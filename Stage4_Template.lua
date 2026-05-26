print("[🛠️ STAGE 4] Nhân vật đã hoàn thành Stage 3 xuất sắc!")
print("[⏳ HOLDING] Script tiến vào trạng thái chờ... Đứng im tại trạm điện và KHÔNG lặp lại Stage 1 nữa.")

-- Vòng lặp vô hạn chạy độc lập để giữ chân nhân vật đứng im tại Power Box
while true do
    task.wait(5)
    -- Vòng lặp này không bao giờ kết thúc, khiến luồng code dừng mãi mãi ở đây cho đến khi bạn viết tính năng mới.
end

-- Trả về false phòng hờ để bẻ gãy hoàn toàn bootloader chính nếu luồng bị tuột ra ngoài
return false
