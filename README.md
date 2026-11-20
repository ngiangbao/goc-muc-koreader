# Góc Mực cho KOReader

Góc Mực là plugin tiếng Việt của [@ngiangbao](https://github.com/ngiangbao), hướng tới Kindle Basic 2024 đã jailbreak và cài KOReader. Plugin mở một trang riêng từ menu KOReader. Cảm hứng đến từ [bài chia sẻ về góc học tập trên Kindle của Nguyễn Việt An](https://www.facebook.com/share/p/1CY1kR7tiE/).

## Cài đặt

1. Tải gói ZIP mới nhất ở [trang phát hành](https://github.com/ngiangbao/goc-muc-koreader/releases/latest).
2. Thoát KOReader về giao diện Kindle rồi cắm cáp USB. Mở bộ nhớ Kindle trên máy tính.
3. Giải nén và chép thư mục `gocmuc.koplugin` vào `koreader/plugins/`. File cần nằm ở `koreader/plugins/gocmuc.koplugin/main.lua`.
4. Ngắt USB, mở lại KOReader và chọn **Công cụ → Góc Mực**.

Dữ liệu ghi chú, thẻ, việc cần làm, nguồn tin đã tải và vị trí thời tiết được lưu trong `gocmuc.lua` ở thư mục thiết lập của KOReader. Để gỡ plugin, thoát KOReader rồi chép thư mục `gocmuc.koplugin` ra ngoài `plugins/`.

## Cờ vua T4 và Lichess

**Cảm ơn Hoàng Tuấn (@hoangtuan2k5), tác giả T4 e-reader OS, đã phát hành hệ thống cờ vua cho cộng đồng Kindle.** Mục **Cờ vua T4 · Hoàng Tuấn** mở thẳng màn Cờ vua của T4 đã cài. T4 cung cấp Stockfish, 5.000 bài thế đi kèm, xem lại và phân tích ván, cùng sảnh cờ trực tuyến của T4. Mã và tài sản T4 được tải trực tiếp từ tác giả. [T4 e-reader OS](https://github.com/hoangtuan2k5/t4-e-reader-os-releases)

1. Tải gói Online hoặc Offline chính thức của [T4 e-reader OS](https://github.com/hoangtuan2k5/t4-e-reader-os-releases/releases/latest). Góc Mực dùng điểm mở màn cờ của T4 v1.6.0.
2. Chép `t4-e-reader-os.koplugin` cạnh `gocmuc.koplugin` trong `koreader/plugins/`.
3. Mở lại KOReader rồi vào **Góc Mực → Cờ vua → Cờ vua T4 · Hoàng Tuấn**.

T4 công bố hỗ trợ Kindle Paperwhite 1. Cần kiểm chứng T4 và Stockfish trên Kindle Basic 2024 thực tế. **Cờ vua cho bé** của Góc Mực chạy cục bộ, có sáu mức đối thủ, gợi ý ô đi, đi lại, hai người chơi và hai bài luyện mở đầu.

Để đăng nhập và đấu bằng tài khoản Lichess, cài riêng **Ink Knight của Beater Studios**, rồi vào **Góc Mực → Cờ vua → Đấu Lichess · Ink Knight**. Chức năng tài khoản chạy trong Ink Knight. Sảnh T4 dùng tài khoản của T4. [Tải Ink Knight](https://github.com/beater-studios/ink_knight.koplugin/releases/latest)

## Cập nhật qua Wi-Fi

Từ **Góc Mực → Cập nhật → Kiểm tra Góc Mực**, plugin kiểm tra bản phát hành GitHub, xác minh chữ ký rồi hỏi trước khi cài và khởi động lại KOReader. Góc Mực giữ một bản sao trong thư mục `gocmuc-backup-<phiên-bản>-<mã>` cạnh plugin. Dữ liệu cá nhân nằm trong thư mục thiết lập của KOReader.

- **T4 e-reader OS** dùng trình cập nhật của Hoàng Tuấn. Chọn **Góc Mực → Cập nhật → Cập nhật T4**, rồi chọn **Cập nhật T4** trong cài đặt của T4. [Hướng dẫn T4](https://github.com/hoangtuan2k5/t4-e-reader-os-releases)
- **Ink Knight** có thể cập nhật qua USB với bản phát hành của Beater Studios. [Bản phát hành Ink Knight](https://github.com/beater-studios/ink_knight.koplugin/releases/latest)

Để phát hành OTA, tăng phiên bản trong `_meta.lua`, ký gói bằng `tools/sign-update.mjs` với khóa riêng tương ứng, rồi đính kèm `gocmuc-update.json` vào GitHub Release mới. Khóa ký được lưu ngoài cây mã nguồn.

## Toán, đọc và tiện ích

| Mục | Tính năng |
| --- | --- |
| Toán tư duy | Năm cấp lớp, luyện 10 câu, đề mô phỏng Kangaroo 24 câu và ASMO 25 câu, hẹn giờ, điểm 3–4–5, câu hỏi ngẫu nhiên và lời giải Việt–Anh. Kangaroo trừ ¼ điểm của câu chọn sai. |
| Cờ caro | Bàn 13 × 13, thắng khi có ít nhất năm quân liên tiếp còn đầu mở, năm mức đối thủ, hai người chung máy, phòng qua Wi-Fi. |
| Đọc báo | Báo Mới, Tuổi Trẻ, Thanh Niên, VnExpress, Znews và Báo Quốc Tế. Ưu tiên nguồn RSS tòa soạn, dùng Google Tin tức khi cần. Có bản tóm tắt, nút trước/sau và hỗ trợ nút cứng trên thiết bị có phím khi đến rìa trang. Nội dung đầy đủ phụ thuộc vào trang bài viết. |
| Lịch để bàn | Ngày âm và dương, lịch tháng, giờ hoàng đạo dân gian, thời tiết hiện tại và dự báo bốn ngày, giá vàng SJC. Địa điểm thời tiết mặc định là TP Hồ Chí Minh và có thể đổi trong plugin. |
| Hợp âm | Hai bài tập mẫu, nội dung tự nhập và nhập từ đường dẫn bài hát công khai trên Hợp Âm Chuẩn. Góc Mực lưu các ký hiệu hợp âm theo từng dòng để xem offline và đổi tông theo nửa cung. |
| Bé đọc | Bộ mẫu truyện kể lại, ca dao, tục ngữ và câu đố. |
| 15 tiện ích | Việc cần làm, thói quen, tập trung, từ vựng, Sudoku, ghi chú, bấm giờ, đếm ngược, đổi đơn vị, máy tính, xúc xắc, đồng xu, bốc số, thẻ tự tạo và nước uống. |

Các đề toán do plugin sinh để luyện. Bản đầu có minh họa bằng ký hiệu và sơ đồ chữ. Báo, giá vàng và thời tiết dùng Wi-Fi. Giá vàng theo dữ liệu của Vang.today và hiển thị mốc thời gian của nguồn.

## Cờ caro giữa Kindle và máy tính

Máy chủ đi kèm chạy bằng Node.js 20 trở lên. Trên máy tính cùng Wi-Fi với Kindle, giải nén gói phát hành rồi chạy lệnh sau trong thư mục giải nén.

```sh
node server/room.mjs
```

1. Tìm địa chỉ IPv4 của máy tính trong mạng Wi-Fi. Ví dụ bên dưới dùng `192.168.1.10`.
2. Trên Kindle, vào **Cờ caro → Chơi theo mã phòng → Địa chỉ máy chủ** rồi nhập `http://192.168.1.10:8080` với IP thực tế của máy tính.
3. Chọn **Tạo phòng** và chia sẻ mã sáu ký tự. Kindle khác kết nối cùng địa chỉ rồi chọn **Vào phòng**. Người dùng máy tính mở địa chỉ đó trong trình duyệt và nhập cùng mã.
4. Giữ máy chủ chạy trong lúc chơi. Phòng hết hạn sau sáu giờ không có nước đi và được lưu trong bộ nhớ máy chủ.

Nếu Windows hỏi về mạng, có thể cho phép Node.js qua tường lửa trên mạng riêng đang dùng để chơi. Máy chủ dự kiến dùng trong LAN. Gói phát hành không kèm dịch vụ được lưu trữ công khai.

## Kiểm tra

```sh
lua tests/core.lua
lua tests/plugin.lua
lua tests/ota.lua
node --test tests/room.test.mjs
```

Các bài kiểm tra dùng logic cục bộ, giao diện KOReader mô phỏng và hai máy khách HTTP. Bản phát hành đầu chưa được chạy trên Kindle Basic 2024 vật lý. Khi báo lỗi, ghi phiên bản KOReader, phiên bản plugin liên quan và trích đoạn `crash.log` sau khi bỏ dữ liệu cá nhân.

## Ghi công

- **Hoàng Tuấn (@hoangtuan2k5)** phát triển T4 e-reader OS, hệ thống cờ vua được mở từ Góc Mực. [T4 e-reader OS](https://github.com/hoangtuan2k5/t4-e-reader-os-releases)
- **Beater Studios** phát triển Ink Knight, ứng dụng được mở từ mục Lichess. [Ink Knight](https://github.com/beater-studios/ink_knight.koplugin)
- **Nguyễn Việt An** chia sẻ ý tưởng góc học tập trên Kindle. [Bài viết gốc](https://www.facebook.com/share/p/1CY1kR7tiE/)
- **Hợp Âm Chuẩn** và những người đóng góp cung cấp các bản hợp âm được nhập theo đường dẫn. [Hợp Âm Chuẩn](https://hopamchuan.com/)
- **Hồ Ngọc Đức** công bố phương pháp lịch âm Việt Nam dựa trên chu kỳ Mặt Trăng và kinh độ Mặt Trời. [Quy tắc lịch âm](https://www.xemamlich.uhm.vn/calrules.html)
- Dự báo và giá vàng lần lượt đến từ [Open-Meteo](https://open-meteo.com/) và [Vang.today](https://www.vang.today/vi/api).
