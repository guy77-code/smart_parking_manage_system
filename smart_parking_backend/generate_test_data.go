package main

import (
	"fmt"
	"log"
	"math/rand"
	"smart_parking_backend/internal/inits"
	"smart_parking_backend/internal/model"
	"time"

	"golang.org/x/crypto/bcrypt"
)

// 车牌前缀列表
var licensePrefixes = []string{"京", "沪", "粤", "川", "苏", "浙", "鲁", "豫", "湘", "鄂", "皖", "闽", "渝", "津", "冀", "晋", "蒙", "辽", "吉", "黑", "赣", "桂", "琼", "贵", "云", "藏", "陕", "甘", "青", "宁", "新"}

// 车牌字母列表
var licenseLetters = []string{"A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}

// 车辆品牌列表
var carBrands = []string{"丰田", "本田", "大众", "奔驰", "宝马", "奥迪", "比亚迪", "吉利", "长城", "长安", "奇瑞", "传祺", "荣威", "名爵", "蔚来", "小鹏", "理想", "特斯拉", "红旗", "领克"}

// 车辆型号列表
var carModels = []string{"卡罗拉", "思域", "朗逸", "C级", "3系", "A4L", "汉", "星越", "H6", "CS75", "瑞虎8", "GS4", "RX5", "MG6", "ES6", "P7", "ONE", "Model 3", "H9", "01"}

// 车辆颜色列表
var carColors = []string{"白色", "黑色", "银色", "灰色", "红色", "蓝色", "棕色", "金色", "绿色", "橙色"}

// 姓名列表
var surnames = []string{"张", "王", "李", "赵", "刘", "陈", "杨", "黄", "周", "吴", "徐", "孙", "马", "朱", "胡", "林", "郭", "何", "高", "罗", "郑", "梁", "谢", "宋", "唐", "许", "韩", "冯", "邓", "曹", "彭", "曾", "肖", "田", "董", "袁", "潘", "于", "蒋", "蔡", "余", "杜", "叶", "程", "苏", "魏", "吕", "丁", "任", "沈"}

var givenNames = []string{"伟", "芳", "娜", "秀英", "敏", "静", "丽", "强", "磊", "军", "洋", "勇", "艳", "杰", "娟", "涛", "明", "超", "秀兰", "霞", "平", "刚", "桂英", "建华", "文", "华", "建国", "红", "建国", "志强", "桂兰", "桂芳", "桂香", "桂芝", "桂芬", "桂英", "桂华", "桂荣", "桂珍", "桂芳", "桂香", "桂芝", "桂芬", "桂英", "桂华", "桂荣", "桂珍"}

func main() {
	// 初始化数据库
	inits.InitDB()
	db := inits.DB

	// 设置随机种子
	rand.Seed(time.Now().UnixNano())

	fmt.Println("==========================================")
	fmt.Println("开始生成测试数据")
	fmt.Println("==========================================")
	fmt.Println()

	// 获取停车场列表
	var lots []model.ParkingLot
	if err := db.Find(&lots).Error; err != nil {
		log.Fatalf("获取停车场列表失败: %v", err)
	}
	if len(lots) == 0 {
		log.Fatalf("未找到停车场，请先创建停车场")
	}

	// 获取车位列表
	var spaces []model.ParkingSpace
	if err := db.Find(&spaces).Error; err != nil {
		log.Fatalf("获取车位列表失败: %v", err)
	}
	if len(spaces) == 0 {
		log.Fatalf("未找到车位，请先创建车位")
	}

	// 密码哈希
	passwordHash, err := bcrypt.GenerateFromPassword([]byte("12345678"), bcrypt.DefaultCost)
	if err != nil {
		log.Fatalf("密码加密失败: %v", err)
	}
	passwordHashStr := string(passwordHash)

	// 生成50个用户
	fmt.Println("1. 生成50个用户及其车辆...")
	users := make([]model.Users_list, 0, 50)
	allVehicles := make([]model.Vehicle, 0, 100)

	for i := 1; i <= 50; i++ {
		// 生成用户信息
		username := fmt.Sprintf("user%03d", i)
		phone := fmt.Sprintf("138%08d", 10000000+i)
		email := fmt.Sprintf("user%03d@example.com", i)
		realName := generateRandomName()

		user := model.Users_list{
			Username:     username,
			PasswordHash: passwordHashStr,
			Phone:        phone,
			Email:        email,
			RealName:     realName,
			RegisterTime: time.Now().AddDate(0, 0, -rand.Intn(180)), // 注册时间：0-180天前
			Status:       1,
		}

		// 创建用户
		if err := db.Create(&user).Error; err != nil {
			log.Printf("创建用户 %d 失败: %v", i, err)
			continue
		}

		users = append(users, user)

		// 为每个用户生成2辆车
		for j := 1; j <= 2; j++ {
			licensePlate := generateLicensePlate()
			brand := carBrands[rand.Intn(len(carBrands))]
			modelName := carModels[rand.Intn(len(carModels))]
			color := carColors[rand.Intn(len(carColors))]

			vehicle := model.Vehicle{
				UserID:       user.UserID,
				LicensePlate: licensePlate,
				Brand:        brand,
				Model:        modelName,
				Color:        color,
				AddTime:      time.Now().AddDate(0, 0, -rand.Intn(150)),
			}

			if err := db.Create(&vehicle).Error; err != nil {
				log.Printf("创建车辆失败 (用户 %d, 车辆 %d): %v", i, j, err)
				continue
			}

			allVehicles = append(allVehicles, vehicle)
		}

		if i%10 == 0 {
			fmt.Printf("  已生成 %d 个用户...\n", i)
		}
	}

	fmt.Printf("✅ 成功生成 %d 个用户，%d 辆车\n\n", len(users), len(allVehicles))

	// 为每个用户生成2-3条停车记录
	fmt.Println("2. 生成停车记录...")
	parkingRecords := make([]model.ParkingRecord, 0)

	for i, user := range users {
		// 每个用户2-3条停车记录
		numRecords := 2 + rand.Intn(2) // 2或3

		// 获取该用户的车辆
		var userVehicles []model.Vehicle
		for _, v := range allVehicles {
			if v.UserID == user.UserID {
				userVehicles = append(userVehicles, v)
			}
		}

		for j := 0; j < numRecords; j++ {
			// 随机选择一辆车
			vehicle := userVehicles[rand.Intn(len(userVehicles))]

			// 随机选择一个停车场和车位
			lot := lots[rand.Intn(len(lots))]
			var availableSpaces []model.ParkingSpace
			for _, s := range spaces {
				if s.LotID == lot.LotID {
					availableSpaces = append(availableSpaces, s)
				}
			}
			if len(availableSpaces) == 0 {
				continue
			}
			space := availableSpaces[rand.Intn(len(availableSpaces))]

			// 生成入场时间（过去30天内）
			entryTime := time.Now().AddDate(0, 0, -rand.Intn(30))
			// 停车时长：30分钟到8小时
			durationMinutes := 30 + rand.Intn(450)
			exitTime := entryTime.Add(time.Duration(durationMinutes) * time.Minute)

			// 计算停车费
			hours := float64(durationMinutes) / 60.0
			feeCalculated := hours * lot.HourlyRate

			// 随机决定是否已支付
			paymentStatus := int8(rand.Intn(2)) // 0或1
			feePaid := 0.0
			if paymentStatus == 1 {
				feePaid = feeCalculated
			}

			// 随机决定是否有违规
			isViolation := int8(0)
			violationReason := ""
			if rand.Float32() < 0.2 { // 20%的概率有违规
				isViolation = 1
				violationReason = "超时停车"
			}

			record := model.ParkingRecord{
				UserID:          user.UserID,
				VehicleID:       vehicle.VehicleID,
				SpaceID:         space.SpaceID,
				LotID:           lot.LotID,
				EntryTime:       entryTime,
				ExitTime:         &exitTime,
				DurationMinutes: durationMinutes,
				FeeCalculated:   feeCalculated,
				FeePaid:         feePaid,
				PaymentStatus:   paymentStatus,
				IsViolation:     isViolation,
				ViolationReason: violationReason,
				RecordStatus:    2, // 已出场
				CreateTime:      entryTime,
			}

			if err := db.Create(&record).Error; err != nil {
				log.Printf("创建停车记录失败 (用户 %d, 记录 %d): %v", i+1, j+1, err)
				continue
			}

			parkingRecords = append(parkingRecords, record)
		}

		if (i+1)%10 == 0 {
			fmt.Printf("  已生成 %d 个用户的停车记录...\n", i+1)
		}
	}

	fmt.Printf("✅ 成功生成 %d 条停车记录\n\n", len(parkingRecords))

	// 为每个用户生成1-2条预订订单记录
	fmt.Println("3. 生成预订订单记录...")
	reservationOrders := make([]model.ReservationOrder, 0)
	reservationCounter := 0

	for i, user := range users {
		// 每个用户1-2条预订订单
		numReservations := 1 + rand.Intn(2) // 1或2

		// 获取该用户的车辆
		var userVehicles []model.Vehicle
		for _, v := range allVehicles {
			if v.UserID == user.UserID {
				userVehicles = append(userVehicles, v)
			}
		}

		for j := 0; j < numReservations; j++ {
			// 随机选择一辆车
			vehicle := userVehicles[rand.Intn(len(userVehicles))]

			// 随机选择一个停车场和车位
			lot := lots[rand.Intn(len(lots))]
			var availableSpaces []model.ParkingSpace
			for _, s := range spaces {
				if s.LotID == lot.LotID {
					availableSpaces = append(availableSpaces, s)
				}
			}
			if len(availableSpaces) == 0 {
				continue
			}
			space := availableSpaces[rand.Intn(len(availableSpaces))]

			// 生成预订时间（过去30天内）
			bookingTime := time.Now().AddDate(0, 0, -rand.Intn(30))
			// 预订开始时间：预订时间后的1-7天
			startTime := bookingTime.AddDate(0, 0, 1+rand.Intn(7))
			// 预订时长：1-4小时
			durationMinutes := 60 + rand.Intn(180)
			endTime := startTime.Add(time.Duration(durationMinutes) * time.Minute)

			// 计算预订费用
			hours := float64(durationMinutes) / 60.0
			totalFee := hours * lot.HourlyRate

			// 随机决定订单状态
			// 0-已取消, 1-已预订, 2-使用中, 3-已完成
			// 先检查是否有对应的停车记录，如果有则更可能标记为已完成
			hasMatchingParkingRecord := false
			for _, record := range parkingRecords {
				if record.UserID == user.UserID &&
					record.VehicleID == vehicle.VehicleID &&
					record.LotID == lot.LotID {
					// 检查时间是否相近（预订开始时间前后2小时内）
					timeDiff := record.EntryTime.Sub(startTime)
					if timeDiff >= -2*time.Hour && timeDiff <= 2*time.Hour {
						hasMatchingParkingRecord = true
						break
					}
				}
			}

			var status int8
			if hasMatchingParkingRecord {
				// 有对应停车记录，更可能是已完成
				if rand.Float32() < 0.7 {
					status = 3 // 已完成
				} else if rand.Float32() < 0.5 {
					status = 2 // 使用中
				} else {
					status = 1 // 已预订
				}
			} else {
				// 没有对应停车记录
				randVal := rand.Float32()
				if randVal < 0.3 {
					status = 0 // 已取消
				} else if randVal < 0.6 {
					status = 1 // 已预订
				} else if randVal < 0.8 {
					status = 2 // 使用中
				} else {
					status = 3 // 已完成（但实际没有停车记录，可能违规）
				}
			}

			// 如果状态是已完成，设置实际结束时间
			actualEndTime := (*time.Time)(nil)
			if status == 3 {
				actualEndTime = &endTime
			}

			// 随机决定是否已支付
			paymentStatus := int8(rand.Intn(2))
			paidFee := 0.0
			if paymentStatus == 1 {
				paidFee = totalFee
			}

			// 生成唯一预订编号
			reservationCounter++
			reservationCode := fmt.Sprintf("RES-%d-%d-%d", user.UserID, time.Now().Unix(), reservationCounter)

			order := model.ReservationOrder{
				UserID:          user.UserID,
				VehicleID:       vehicle.VehicleID,
				SpaceID:         space.SpaceID,
				LotID:           lot.LotID,
				StartTime:       startTime,
				EndTime:         endTime,
				ActualEndTime:   actualEndTime,
				DurationMinutes: durationMinutes,
				BookingTime:     bookingTime,
				Status:          status,
				TotalFee:        totalFee,
				PaidFee:         paidFee,
				PaymentStatus:   paymentStatus,
				ReservationCode: reservationCode,
			}

			if err := db.Create(&order).Error; err != nil {
				log.Printf("创建预订订单失败 (用户 %d, 订单 %d): %v", i+1, j+1, err)
				continue
			}

			reservationOrders = append(reservationOrders, order)
		}

		if (i+1)%10 == 0 {
			fmt.Printf("  已生成 %d 个用户的预订订单...\n", i+1)
		}
	}

	fmt.Printf("✅ 成功生成 %d 条预订订单记录\n\n", len(reservationOrders))

	// 生成支付记录
	fmt.Println("4. 生成支付记录...")
	paymentRecords := make([]model.PaymentRecord, 0)

	// 为预订订单生成支付记录
	for _, order := range reservationOrders {
		if order.PaymentStatus == 1 { // 已支付
			paymentMethods := []string{"wechat", "alipay"}
			method := paymentMethods[rand.Intn(len(paymentMethods))]

			payTime := order.BookingTime.Add(time.Duration(rand.Intn(3600)) * time.Second) // 预订后1小时内支付

			transactionNo := fmt.Sprintf("TXN%d%d", time.Now().UnixNano(), rand.Intn(10000))

			payment := model.PaymentRecord{
				OrderID:       order.OrderID,
				UserID:        order.UserID,
				Amount:        order.PaidFee,
				Method:        method,
				TransactionNo: transactionNo,
				PaymentStatus: 1, // 已支付
				PayTime:       &payTime,
				CreateTime:    order.BookingTime,
			}

			if err := db.Create(&payment).Error; err != nil {
				log.Printf("创建支付记录失败 (订单 %d): %v", order.OrderID, err)
				continue
			}

			paymentRecords = append(paymentRecords, payment)
		}
	}

	// 为停车记录生成支付记录
	sqlDB, err := db.DB()
	if err != nil {
		log.Printf("获取数据库连接失败: %v", err)
	} else {
		// 临时禁用外键检查
		sqlDB.Exec("SET FOREIGN_KEY_CHECKS = 0")
		defer sqlDB.Exec("SET FOREIGN_KEY_CHECKS = 1")

		for _, record := range parkingRecords {
			if record.PaymentStatus == 1 { // 已支付
				paymentMethods := []string{"wechat", "alipay"}
				method := paymentMethods[rand.Intn(len(paymentMethods))]

				payTime := *record.ExitTime
				payTime = payTime.Add(time.Duration(rand.Intn(1800)) * time.Second) // 出场后30分钟内支付

				transactionNo := fmt.Sprintf("TXN%d%d", time.Now().UnixNano(), rand.Intn(10000))

				// 使用原生SQL插入，避免外键约束问题
				result, err := sqlDB.Exec(
					"INSERT INTO payment_record (order_id, user_id, amount, method, transaction_no, payment_status, pay_time, create_time) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
					record.RecordID, record.UserID, record.FeePaid, method, transactionNo, 1, payTime, *record.ExitTime,
				)
				if err != nil {
					log.Printf("创建停车支付记录失败 (记录 %d): %v", record.RecordID, err)
					continue
				}

				paymentID, _ := result.LastInsertId()
				payment := model.PaymentRecord{
					PaymentID:     uint64(paymentID),
					OrderID:       record.RecordID,
					UserID:        record.UserID,
					Amount:        record.FeePaid,
					Method:        method,
					TransactionNo: transactionNo,
					PaymentStatus: 1,
					PayTime:       &payTime,
					CreateTime:    *record.ExitTime,
				}
				paymentRecords = append(paymentRecords, payment)
			}
		}
	}

	fmt.Printf("✅ 成功生成 %d 条支付记录\n\n", len(paymentRecords))

	// 生成违规记录
	fmt.Println("5. 生成违规记录...")
	violationRecords := make([]model.ViolationRecord, 0)

	// 为有违规的停车记录生成违规记录
	for _, record := range parkingRecords {
		if record.IsViolation == 1 {
			violationTime := record.EntryTime.Add(time.Duration(rand.Intn(int(record.DurationMinutes))) * time.Minute)

			// 随机决定是否已处理
			status := int8(rand.Intn(2))
			processTime := (*time.Time)(nil)
			if status == 1 {
				pt := violationTime.Add(time.Duration(rand.Intn(7*24*3600)) * time.Second) // 7天内处理
				processTime = &pt
			}

			// 罚款金额：停车费的0.5-2倍
			fineAmount := record.FeeCalculated * (0.5 + rand.Float64()*1.5)

			violation := model.ViolationRecord{
				RecordID:      record.RecordID,
				UserID:        record.UserID,
				VehicleID:     record.VehicleID,
				ViolationType: record.ViolationReason,
				ViolationTime: violationTime,
				Description:   fmt.Sprintf("停车记录 %d 的违规行为", record.RecordID),
				FineAmount:    fineAmount,
				Status:        status,
				ProcessTime:   processTime,
				CreateTime:    violationTime,
			}

			if err := db.Create(&violation).Error; err != nil {
				log.Printf("创建违规记录失败 (记录 %d): %v", record.RecordID, err)
				continue
			}

			violationRecords = append(violationRecords, violation)
		}
	}

	// 为未使用的预订生成违规记录
	for _, order := range reservationOrders {
		// 如果预订已过期但未使用（状态为1且结束时间已过）
		if order.Status == 1 && order.EndTime.Before(time.Now()) {
			// 检查是否有对应的停车记录
			hasParkingRecord := false
			for _, record := range parkingRecords {
				if record.UserID == order.UserID &&
					record.VehicleID == order.VehicleID &&
					record.LotID == order.LotID {
					timeDiff := record.EntryTime.Sub(order.StartTime)
					if timeDiff >= -time.Hour && timeDiff <= time.Hour {
						hasParkingRecord = true
						break
					}
				}
			}

			// 如果没有对应的停车记录，说明预订未使用
			if !hasParkingRecord {
				violationTime := order.EndTime.Add(30 * time.Minute) // 预订结束后30分钟

				status := int8(rand.Intn(2))
				processTime := (*time.Time)(nil)
				if status == 1 {
					pt := violationTime.Add(time.Duration(rand.Intn(7*24*3600)) * time.Second)
					processTime = &pt
				}

				// 罚款金额：预订费用的1-3倍
				fineAmount := order.TotalFee * (1.0 + rand.Float64()*2.0)

				// 需要找到对应的停车记录ID（如果没有，使用0）
				recordID := uint(0)
				for _, record := range parkingRecords {
					if record.UserID == order.UserID &&
						record.VehicleID == order.VehicleID &&
						record.LotID == order.LotID {
						recordID = record.RecordID
						break
					}
				}

				violation := model.ViolationRecord{
					RecordID:      recordID,
					UserID:        order.UserID,
					VehicleID:     order.VehicleID,
					ViolationType: "预订未使用",
					ViolationTime: violationTime,
					Description:   fmt.Sprintf("预订订单 %s 未在规定时间内使用", order.ReservationCode),
					FineAmount:    fineAmount,
					Status:        status,
					ProcessTime:   processTime,
					CreateTime:    violationTime,
				}

				if err := db.Create(&violation).Error; err != nil {
					log.Printf("创建预订违规记录失败 (订单 %d): %v", order.OrderID, err)
					continue
				}

				violationRecords = append(violationRecords, violation)
			}
		}
	}

	fmt.Printf("✅ 成功生成 %d 条违规记录\n\n", len(violationRecords))

	fmt.Println("==========================================")
	fmt.Println("数据生成完成！")
	fmt.Println("==========================================")
	fmt.Printf("用户数量: %d\n", len(users))
	fmt.Printf("车辆数量: %d\n", len(allVehicles))
	fmt.Printf("停车记录: %d\n", len(parkingRecords))
	fmt.Printf("预订订单: %d\n", len(reservationOrders))
	fmt.Printf("支付记录: %d\n", len(paymentRecords))
	fmt.Printf("违规记录: %d\n", len(violationRecords))
	fmt.Println()
	fmt.Println("所有用户密码: 12345678")
}

// 生成随机车牌号
func generateLicensePlate() string {
	prefix := licensePrefixes[rand.Intn(len(licensePrefixes))]
	letter := licenseLetters[rand.Intn(len(licenseLetters))]
	number := fmt.Sprintf("%05d", rand.Intn(100000))
	return fmt.Sprintf("%s%s%s", prefix, letter, number)
}

// 生成随机姓名
func generateRandomName() string {
	surname := surnames[rand.Intn(len(surnames))]
	givenName := givenNames[rand.Intn(len(givenNames))]
	if rand.Float32() < 0.3 { // 30%的概率是两个字的名字
		givenName2 := givenNames[rand.Intn(len(givenNames))]
		return surname + givenName + givenName2
	}
	return surname + givenName
}

