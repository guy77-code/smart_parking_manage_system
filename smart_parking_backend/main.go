package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"smart_parking_backend/internal/booking"
	"smart_parking_backend/internal/controller"
	"smart_parking_backend/internal/inits"
	"smart_parking_backend/internal/payment"
	"smart_parking_backend/pkg/logger"
	router "smart_parking_backend/routers"
	"syscall"
	"time"
)


//lisi2024     12345678 clienttest
func main() {
	// 初始化日志
	logger.InitLogger()

	// 初始化数据库 & Redis
	inits.InitDB()
	rclient, err := inits.InitRedis(context.Background(), "config/config.yaml")
	if err != nil {
		log.Fatalf("❌ Failed to init redis: %v", err)
	}
	defer func() {
		if rclient != nil {
			_ = rclient.Close()
		}
	}()

	// 初始化模块服务
	repo := booking.NewRepository()
	bookingSvc := booking.NewService(repo)

	cfg, err := payment.LoadSandboxConfig("config/payment_sandbox.yaml")
	if err != nil {
		log.Fatalf("加载支付配置失败: %v", err)
	}

	paymentSvc := payment.NewService(bookingSvc, cfg)

	// 初始化控制器的支付服务
	controller.InitPaymentService(paymentSvc)

	// 初始化路由
	r := router.InitRouter(bookingSvc, paymentSvc)

	port := ":8080"

	// 创建 HTTP 服务器
	srv := &http.Server{
		Addr:    port,
		Handler: r,
	}

	// 在 goroutine 中启动服务器
	go func() {
		fmt.Printf("🔄 尝试在端口 %s 启动 HTTP 服务器...\n", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("❌ 服务器启动失败: %v", err)
		}
	}()

	// 等待服务器启动并检测端口
	fmt.Println("🔍 检查服务器是否已成功启动...")
	if !isServerReady(port, 5, 500*time.Millisecond) {
		log.Fatalf("❌ 服务器启动失败，端口 %s 无法连接", port)
	}
	fmt.Printf("✅ Smart Parking 后端服务已在端口 %s 成功启动并正在运行\n", port)

	// ================== 修复静态检查错误的关键修改 ==================
	// 使用更简单的通道操作替代只有一个 case 的 select
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	// 等待中断信号
	<-quit
	log.Println("🛑 收到停止信号，正在关闭服务器...")

	// 优雅关闭服务器
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("❌ 强制关闭服务器: %v", err)
	}
	log.Println("✅ 服务器已关闭")
}

// isServerReady 尝试连接指定端口，确认服务器是否已就绪
func isServerReady(port string, maxAttempts int, interval time.Duration) bool {
	for i := 0; i < maxAttempts; i++ {
		address := "127.0.0.1" + port
		conn, err := net.DialTimeout("tcp", address, 1*time.Second)
		if err == nil {
			conn.Close()
			return true
		}

		if i < maxAttempts-1 {
			fmt.Printf("⏳ 端口检查尝试 %d/%d 失败，%v后重试...\n", i+1, maxAttempts, interval)
			time.Sleep(interval)
		}
	}
	return false
}
