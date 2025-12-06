package router

import (
	"smart_parking_backend/internal/booking"
	"smart_parking_backend/internal/controller"
	"smart_parking_backend/internal/inits"
	"smart_parking_backend/internal/middleware"
	"smart_parking_backend/internal/payment"

	"github.com/gin-gonic/gin"
)

func InitRouter(bookingSvc *booking.Service, paymentCfg *payment.Service) *gin.Engine {
	r := gin.Default()

	// 全局中间件
	r.Use(middleware.Cors())
	r.MaxMultipartMemory = 8 << 20 // 8 MiB

	// -------------------- 用户模块 --------------------
	api := r.Group("/api/v1/")
	{
		api.POST("/register", controller.Register(inits.DB))
		api.POST("/send_code", controller.SendLoginCode(inits.RedisClient))
		api.POST("/login", controller.Login(inits.DB, inits.RedisClient))

		// 需要用户认证的路由
		protectedUserGroup := api.Use(middleware.UserAuthMiddleware())
		{
			protectedUserGroup.GET("/getpaymentinfo", controller.GetUserPaymentRecords(inits.DB)) //从token获取user_id
			// 获取 / 管理当前登录用户的车辆
			protectedUserGroup.GET("/vehicles", controller.GetUserVehicles(inits.DB))
			protectedUserGroup.POST("/vehicles", controller.AddUserVehicle(inits.DB))
			protectedUserGroup.DELETE("/vehicles/:id", controller.DeleteUserVehicle(inits.DB))
		}
	}

	// -------------------- 管理员模块 --------------------
	adminGroup := r.Group("/admin")
	{
		adminGroup.POST("/register", controller.AdminRegisterController)
		adminGroup.POST("/login", controller.AdminLoginController)

		// 需要认证的管理员路由
		protectedGroup := adminGroup.Use(middleware.AdminAuthMiddleware())
		{
			protectedGroup.GET("/occupancy", controller.ParkingSpaceOccupancyAnalysis) // 车位使用率分析
			protectedGroup.GET("/violations", controller.ViolationAnalysis)            // 违规行为分析
			protectedGroup.GET("/report", controller.GenerateReport)                   // 报表生成
		}
	}

	// -------------------- 停车场模块 --------------------
	api_1 := r.Group("/api/v2")
	{
		api_1.POST("/addparkinglot", controller.AddParkingLot)
		api_1.GET("/getparkinglots", controller.GetAllParkingLots)
		api_1.GET("/getparkinglot/:id", controller.GetParkingLotByID)
		api_1.DELETE("/deleteparkinglot/:id", controller.DeleteParkingLot)
		api_1.POST("/addparkingspace", controller.AddParkingSpace)
		api_1.PATCH("/updatespacestatus/:id", controller.UpdateSpaceStatus)
		api_1.GET("/getspacesbylotid/:lot_id", controller.GetSpacesByLotID)
	}

	// -------------------- 车位模块 --------------------
	api_2 := r.Group("/api/v3")
	{
		api_2.POST("/addparkingspace", controller.AddParkingSpace)
		api_2.PATCH("/updatespacestatus/:id", controller.UpdateSpaceStatus)
		api_2.GET("/getspacesbylotid/:lot_id", controller.GetSpacesByLotID)
	}

	// -------------------- 预订模块 --------------------
	booking.BookingRoutes(r, bookingSvc)

	// -------------------- 停车模块 --------------------
	parkingGroup := r.Group("/api/parking")
	{
		// 注意：具体路由要放在参数路由之前，避免路由冲突
		parkingGroup.POST("/entry", controller.VehicleEntry)                                   // 车辆入场
		parkingGroup.POST("/exit", controller.VehicleExit)                                     // 车辆出场
		parkingGroup.POST("/check-reservation", controller.CheckValidReservation)              // 检查有效预订（进场前确认）
		parkingGroup.GET("/space-types", controller.GetParkingSpaceTypes)                      // 获取车位类型
		parkingGroup.GET("/getlicense/:license_plate", controller.GetVehicleByLicensePlate)    // 根据车牌号获取车辆信息
		parkingGroup.GET("/getparkinglotoccupancy/:lot_id", controller.GetParkingLotOccupancy) // 实时获取停车场车位信息
		parkingGroup.GET("/lots/:lot_id/spaces", controller.GetParkingLotSpaces)               // 获取停车场车位信息
		parkingGroup.GET("/:user_id/active-parking", controller.GetUserActiveParkingRecords)   // 获取用户在场停车记录（放在最后，避免冲突）
	}

	//违规管理路由
	violationGroup := r.Group("/api/violations")
	{
		violationGroup.POST("/check", controller.CheckViolations)                       // 检查违规行为
		violationGroup.GET("/checkmyself/:user_id", controller.GetUserViolationHistory) // 检查用户违规记录
	}

	// -------------------- 支付模块 --------------------
	payment.PaymentRoutes(r, bookingSvc, paymentCfg.Config())

	violationPaymentGroup := r.Group("/api/violations")
	{
		violationPaymentGroup.POST("/:violation_id/pay", controller.PayViolationFine) // 支付罚款
	}

	return r
}
