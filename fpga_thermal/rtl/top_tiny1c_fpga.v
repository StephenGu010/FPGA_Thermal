// -----------------------------------------------------------------------------
// Module: top_tiny1c_fpga
// Function: raw stream -> norm -> ROI -> scaler -> Sobel blend -> packet to ESP32-S3.
// Boundaries: no AI/NPU, no YOLO/ESRGAN, no AMOLED driver.
// Timing: P0 uses frame-buffered scaler/output packet memories for bring-up.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module top_tiny1c_fpga #(
    parameter RAW_WIDTH = 256,
    parameter RAW_HEIGHT = 192,
    parameter FULL_DISPLAY_WIDTH = 168,
    parameter FULL_DISPLAY_HEIGHT = 126,
    parameter OBS_DISPLAY_WIDTH = 294,
    parameter OBS_DISPLAY_HEIGHT = 126,
    parameter THUMB_WIDTH = 64,
    parameter THUMB_HEIGHT = 48,
    parameter USE_BILINEAR = 0,
    parameter SPI_CLK_DIV = 2,
    parameter PACKET_BUFFER_DISPLAY = 0
) (
    input wire clk,
    input wire rst_n,
    input wire tiny_spi_sclk,
    input wire tiny_spi_cs_n,
    input wire tiny_spi_mosi,
    input wire tiny_frame_sync,
    input wire direct_in_enable,
    input wire [15:0] direct_pixel,
    input wire direct_valid,
    input wire direct_frame_start,
    input wire direct_frame_end,
    input wire [15:0] direct_x,
    input wire [15:0] direct_y,
    input wire cfg_we,
    input wire [7:0] cfg_addr,
    input wire [31:0] cfg_wdata,
    output wire [31:0] cfg_rdata,
    output wire esp_spi_cs_n,
    output wire esp_spi_sclk,
    output wire esp_spi_mosi,
    output wire packet_busy,
    output wire packet_done,
    output wire frame_error
);
localparam DISPLAY_MAX_WIDTH = OBS_DISPLAY_WIDTH;
localparam DISPLAY_MAX_HEIGHT = OBS_DISPLAY_HEIGHT;
localparam DISPLAY_MAX_PIXELS = DISPLAY_MAX_WIDTH * DISPLAY_MAX_HEIGHT;
localparam DISPLAY_MEM_PIXELS = PACKET_BUFFER_DISPLAY ? DISPLAY_MAX_PIXELS : 1;
localparam THUMB_PIXELS = THUMB_WIDTH * THUMB_HEIGHT;
localparam MASK_BYTES = (THUMB_PIXELS + 7) / 8;
localparam [15:0] RAW_WIDTH_U16 = RAW_WIDTH;
localparam [15:0] RAW_HEIGHT_U16 = RAW_HEIGHT;
localparam [15:0] FULL_DISPLAY_WIDTH_U16 = FULL_DISPLAY_WIDTH;
localparam [15:0] FULL_DISPLAY_HEIGHT_U16 = FULL_DISPLAY_HEIGHT;
localparam [15:0] OBS_DISPLAY_WIDTH_U16 = OBS_DISPLAY_WIDTH;
localparam [15:0] OBS_DISPLAY_HEIGHT_U16 = OBS_DISPLAY_HEIGHT;
localparam [15:0] THUMB_WIDTH_U16 = THUMB_WIDTH;
localparam [15:0] THUMB_HEIGHT_U16 = THUMB_HEIGHT;

wire [15:0] spi_pixel, spi_x, spi_y;
wire spi_valid, spi_fs, spi_fe;
spi_rx_tiny1c #(.FRAME_WIDTH(RAW_WIDTH), .FRAME_HEIGHT(RAW_HEIGHT), .BITS_PER_PIXEL(16)) u_rx (
    .clk(clk), .rst_n(rst_n), .spi_sclk(tiny_spi_sclk), .spi_cs_n(tiny_spi_cs_n),
    .spi_mosi(tiny_spi_mosi), .frame_sync(tiny_frame_sync), .pixel_data(spi_pixel),
    .pixel_valid(spi_valid), .frame_start(spi_fs), .frame_end(spi_fe),
    .frame_error(frame_error), .x(spi_x), .y(spi_y)
);
wire [15:0] raw_pixel = direct_in_enable ? direct_pixel : spi_pixel;
wire raw_valid = direct_in_enable ? direct_valid : spi_valid;
wire raw_fs = direct_in_enable ? direct_frame_start : spi_fs;
wire raw_fe = direct_in_enable ? direct_frame_end : spi_fe;
wire [15:0] raw_x = direct_in_enable ? direct_x : spi_x;
wire [15:0] raw_y = direct_in_enable ? direct_y : spi_y;

wire display_mode, edge_enable;
wire [7:0] edge_gain, edge_threshold;
wire [15:0] raw_low_threshold, raw_high_threshold, cfg_roi_x0, cfg_roi_y0, cfg_roi_w, cfg_roi_h;
cfg_regs #(.RAW_WIDTH(RAW_WIDTH), .RAW_HEIGHT(RAW_HEIGHT)) u_cfg (
    .clk(clk), .rst_n(rst_n), .cfg_we(cfg_we), .cfg_addr(cfg_addr), .cfg_wdata(cfg_wdata), .cfg_rdata(cfg_rdata),
    .display_mode(display_mode), .edge_enable(edge_enable), .edge_gain(edge_gain), .edge_threshold(edge_threshold),
    .raw_low_threshold(raw_low_threshold), .raw_high_threshold(raw_high_threshold),
    .roi_x0(cfg_roi_x0), .roi_y0(cfg_roi_y0), .roi_w(cfg_roi_w), .roi_h(cfg_roi_h)
);
wire [15:0] roi_x0_sel = display_mode ? cfg_roi_x0 : 0;
wire [15:0] roi_y0_sel = display_mode ? cfg_roi_y0 : 0;
wire [15:0] roi_w_sel = display_mode ? cfg_roi_w : RAW_WIDTH_U16;
wire [15:0] roi_h_sel = display_mode ? cfg_roi_h : RAW_HEIGHT_U16;
wire [15:0] disp_w_sel = display_mode ? OBS_DISPLAY_WIDTH_U16 : FULL_DISPLAY_WIDTH_U16;
wire [15:0] disp_h_sel = display_mode ? OBS_DISPLAY_HEIGHT_U16 : FULL_DISPLAY_HEIGHT_U16;

wire [15:0] m_min,m_max,m_center,m_hot,m_hx,m_hy,m_cx,m_cy;
wire [31:0] m_count;
wire m_valid;
meta_extract #(.FRAME_WIDTH(RAW_WIDTH), .FRAME_HEIGHT(RAW_HEIGHT)) u_meta (
    .clk(clk), .rst_n(rst_n), .raw_in(raw_pixel), .in_valid(raw_valid), .in_frame_start(raw_fs), .in_frame_end(raw_fe),
    .in_x(raw_x), .in_y(raw_y), .raw_low_threshold(raw_low_threshold), .raw_high_threshold(raw_high_threshold),
    .raw_min(m_min), .raw_max(m_max), .raw_center(m_center), .raw_hotspot(m_hot), .hotspot_x(m_hx), .hotspot_y(m_hy),
    .candidate_count(m_count), .candidate_cx(m_cx), .candidate_cy(m_cy), .meta_valid(m_valid)
);

wire [7:0] gray; wire gray_valid, gray_fs, gray_fe; wire [15:0] gray_x, gray_y;
norm16_to_u8 u_norm (
    .clk(clk), .rst_n(rst_n), .raw_in(raw_pixel), .in_valid(raw_valid), .in_frame_start(raw_fs), .in_frame_end(raw_fe),
    .in_x(raw_x), .in_y(raw_y), .minmax_enable(1'b0), .raw_min(m_min), .raw_max(m_max),
    .gray_out(gray), .out_valid(gray_valid), .out_frame_start(gray_fs), .out_frame_end(gray_fe), .out_x(gray_x), .out_y(gray_y)
);

wire [7:0] thumb_gray; wire thumb_valid; wire [15:0] thumb_x, thumb_y;
thumb_gen #(.IN_WIDTH(RAW_WIDTH), .IN_HEIGHT(RAW_HEIGHT), .THUMB_WIDTH(THUMB_WIDTH), .THUMB_HEIGHT(THUMB_HEIGHT)) u_thumb (
    .clk(clk), .rst_n(rst_n), .gray_in(gray), .in_valid(gray_valid), .in_x(gray_x), .in_y(gray_y),
    .thumb_gray(thumb_gray), .thumb_valid(thumb_valid), .thumb_frame_start(), .thumb_frame_end(), .thumb_x(thumb_x), .thumb_y(thumb_y)
);

wire cand_mask, cand_valid; wire [15:0] cand_x, cand_y;
candidate_mask_gen #(.IN_WIDTH(RAW_WIDTH), .IN_HEIGHT(RAW_HEIGHT), .MASK_WIDTH(THUMB_WIDTH), .MASK_HEIGHT(THUMB_HEIGHT)) u_mask (
    .clk(clk), .rst_n(rst_n), .raw_in(raw_pixel), .in_valid(raw_valid), .in_frame_start(raw_fs), .in_frame_end(raw_fe),
    .in_x(raw_x), .in_y(raw_y), .raw_low_threshold(raw_low_threshold), .raw_high_threshold(raw_high_threshold),
    .candidate_mask(cand_mask), .mask_valid(cand_valid), .mask_frame_start(), .mask_frame_end(), .mask_x(cand_x), .mask_y(cand_y),
    .candidate_count(), .candidate_sum_x(), .candidate_sum_y(), .candidate_count_valid()
);

wire [7:0] roi_pix; wire roi_valid, roi_fs, roi_fe; wire [15:0] roi_x, roi_y;
roi_crop #(.PIXEL_WIDTH(8)) u_roi (
    .clk(clk), .rst_n(rst_n), .pixel_in(gray), .in_valid(gray_valid), .in_x(gray_x), .in_y(gray_y),
    .roi_x0(roi_x0_sel), .roi_y0(roi_y0_sel), .roi_w(roi_w_sel), .roi_h(roi_h_sel),
    .pixel_out(roi_pix), .out_valid(roi_valid), .out_frame_start(roi_fs), .out_frame_end(roi_fe), .out_x(roi_x), .out_y(roi_y)
);

wire [7:0] scale_pix; wire scale_valid, scale_fe; wire [15:0] scale_x, scale_y; wire scale_busy;
generate
if (USE_BILINEAR) begin : g_bi
    scaler_bilinear #(.MAX_IN_WIDTH(RAW_WIDTH), .MAX_IN_HEIGHT(RAW_HEIGHT), .PIXEL_WIDTH(8)) u_scaler (
        .clk(clk), .rst_n(rst_n), .pixel_in(roi_pix), .in_valid(roi_valid), .in_frame_start(roi_fs), .in_frame_end(roi_fe),
        .in_x(roi_x), .in_y(roi_y), .in_width(roi_w_sel), .in_height(roi_h_sel), .out_width_cfg(disp_w_sel), .out_height_cfg(disp_h_sel),
        .pixel_out(scale_pix), .out_valid(scale_valid), .out_frame_start(), .out_frame_end(scale_fe), .out_x(scale_x), .out_y(scale_y), .busy(scale_busy)
    );
end else begin : g_nn
    scaler_nearest #(.MAX_IN_WIDTH(RAW_WIDTH), .MAX_IN_HEIGHT(RAW_HEIGHT), .PIXEL_WIDTH(8)) u_scaler (
        .clk(clk), .rst_n(rst_n), .pixel_in(roi_pix), .in_valid(roi_valid), .in_frame_start(roi_fs), .in_frame_end(roi_fe),
        .in_x(roi_x), .in_y(roi_y), .in_width(roi_w_sel), .in_height(roi_h_sel), .out_width_cfg(disp_w_sel), .out_height_cfg(disp_h_sel),
        .pixel_out(scale_pix), .out_valid(scale_valid), .out_frame_start(), .out_frame_end(scale_fe), .out_x(scale_x), .out_y(scale_y), .busy(scale_busy)
    );
end
endgenerate

wire [7:0] sobel_center, sobel_edge; wire sobel_valid; wire [15:0] sobel_x, sobel_y;
sobel3x3 #(.WIDTH(DISPLAY_MAX_WIDTH)) u_sobel (
    .clk(clk), .rst_n(rst_n), .gray_in(scale_pix), .in_valid(scale_valid), .in_x(scale_x), .in_y(scale_y),
    .edge_threshold(edge_threshold), .center_gray(sobel_center), .edge_strength(sobel_edge), .edge_mask(),
    .out_valid(sobel_valid), .out_x(sobel_x), .out_y(sobel_y)
);
wire [7:0] blend_gray; wire blend_valid; wire [15:0] blend_x, blend_y;
edge_blend u_blend (
    .clk(clk), .rst_n(rst_n), .gray_in(sobel_center), .edge_strength(sobel_edge), .edge_enable(edge_enable), .edge_gain(edge_gain),
    .in_valid(sobel_valid), .in_x(sobel_x), .in_y(sobel_y), .gray_out(blend_gray), .out_valid(blend_valid), .out_x(blend_x), .out_y(blend_y)
);

reg [7:0] display_mem [0:DISPLAY_MEM_PIXELS-1] /* synthesis syn_ramstyle="block_ram" */;
reg [7:0] thumb_mem [0:THUMB_PIXELS-1] /* synthesis syn_ramstyle="block_ram" */;
reg [7:0] mask_mem [0:MASK_BYTES-1];
integer i;
reg [15:0] l_disp_w,l_disp_h,l_flags,l_min,l_max,l_center,l_hot,l_hx,l_hy,l_cx,l_cy,frame_id;
reg [31:0] l_count;
reg meta_seen, scale_seen, packet_start_req;
wire [31:0] baddr = blend_y * disp_w_sel + blend_x;
wire [31:0] taddr = thumb_y * THUMB_WIDTH + thumb_x;
wire [31:0] midx = cand_y * THUMB_WIDTH + cand_x;
wire [31:0] mbyte = midx >> 3;
wire [2:0] mbit = 3'd7 - midx[2:0];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        l_disp_w <= FULL_DISPLAY_WIDTH_U16; l_disp_h <= FULL_DISPLAY_HEIGHT_U16; l_flags <= 0;
        l_min <= 0; l_max <= 0; l_center <= 0; l_hot <= 0; l_hx <= 0; l_hy <= 0; l_count <= 0; l_cx <= 0; l_cy <= 0;
        meta_seen <= 0; scale_seen <= 0; packet_start_req <= 0; frame_id <= 0;
        for (i=0; i<MASK_BYTES; i=i+1) mask_mem[i] <= 0;
    end else begin
        if (raw_fs && raw_valid) begin
            meta_seen <= 0; scale_seen <= 0; packet_start_req <= 0;
            for (i=0; i<MASK_BYTES; i=i+1) mask_mem[i] <= 0;
        end
        if (thumb_valid) thumb_mem[taddr] <= thumb_gray;
        if (cand_valid) mask_mem[mbyte][mbit] <= cand_mask;
        if (PACKET_BUFFER_DISPLAY && blend_valid) display_mem[baddr] <= blend_gray;
        if (m_valid) begin
            l_disp_w <= disp_w_sel; l_disp_h <= disp_h_sel; l_flags <= {14'd0, edge_enable, display_mode};
            l_min <= m_min; l_max <= m_max; l_center <= m_center; l_hot <= m_hot; l_hx <= m_hx; l_hy <= m_hy;
            l_count <= m_count; l_cx <= m_cx; l_cy <= m_cy; meta_seen <= 1'b1;
        end
        if (scale_valid && scale_fe) scale_seen <= 1'b1;
        if (meta_seen && scale_seen && !packet_busy && !packet_start_req) begin packet_start_req <= 1'b1; frame_id <= frame_id + 1'b1; end
        else if (packet_start_req && packet_busy) packet_start_req <= 1'b0;
    end
end

reg [1:0] psec; reg [31:0] pidx; reg [7:0] pdata; reg pvalid, plast;
reg [31:0] display_read_idx;
reg [7:0] display_read_data;
reg [15:0] payload_x;
reg [15:0] payload_y;
wire payload_boundary = (payload_x == 0) || (payload_y == 0) ||
                        (payload_x == l_disp_w - 1) || (payload_y == l_disp_h - 1);
wire pready;
wire [31:0] display_payload_len = l_disp_w * l_disp_h;
wire [31:0] payload_len = display_payload_len + THUMB_PIXELS + MASK_BYTES;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        psec <= 0; pidx <= 0; pdata <= 0; pvalid <= 0; plast <= 0;
        display_read_idx <= 0; display_read_data <= 0; payload_x <= 0; payload_y <= 0;
    end
    else begin
        pvalid <= 0; plast <= 0;
        display_read_data <= PACKET_BUFFER_DISPLAY ? display_mem[display_read_idx] : 8'd0;
        if (packet_start_req) begin psec <= 0; pidx <= 0; display_read_idx <= 0; payload_x <= 0; payload_y <= 0; end
        else if (pready) begin
            pvalid <= 1'b1;
            if (psec == 0) begin
                display_read_idx <= pidx + 1'b1;
                pdata <= (PACKET_BUFFER_DISPLAY && !payload_boundary) ? display_read_data : 8'd0;
                if (pidx == display_payload_len - 1) begin
                    psec <= 1; pidx <= 0; payload_x <= 0; payload_y <= 0;
                end else begin
                    pidx <= pidx + 1'b1;
                    if (payload_x == l_disp_w - 1) begin payload_x <= 0; payload_y <= payload_y + 1'b1; end
                    else payload_x <= payload_x + 1'b1;
                end
            end else if (psec == 1) begin
                pdata <= thumb_mem[pidx];
                if (pidx == THUMB_PIXELS - 1) begin psec <= 2; pidx <= 0; end else pidx <= pidx + 1'b1;
            end else begin
                pdata <= mask_mem[pidx]; plast <= (pidx == MASK_BYTES - 1);
                if (pidx == MASK_BYTES - 1) pidx <= 0; else pidx <= pidx + 1'b1;
            end
        end
    end
end
packet_tx_spi #(.CLK_DIV(SPI_CLK_DIV)) u_tx (
    .clk(clk), .rst_n(rst_n), .start(packet_start_req), .frame_id(frame_id),
    .display_width(l_disp_w), .display_height(l_disp_h), .thumb_width(THUMB_WIDTH_U16), .thumb_height(THUMB_HEIGHT_U16),
    .flags(l_flags), .raw_min(l_min), .raw_max(l_max), .raw_center(l_center), .raw_hotspot(l_hot), .hotspot_x(l_hx), .hotspot_y(l_hy),
    .candidate_count(l_count), .candidate_cx(l_cx), .candidate_cy(l_cy), .payload_len(payload_len), .header_checksum(16'd0),
    .payload_data(pdata), .payload_valid(pvalid), .payload_last(plast), .payload_ready(pready),
    .spi_cs_n(esp_spi_cs_n), .spi_sclk(esp_spi_sclk), .spi_mosi(esp_spi_mosi), .busy(packet_busy), .done(packet_done), .crc_out()
);
endmodule
