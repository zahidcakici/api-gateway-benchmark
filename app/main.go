package main

import (
	"os"

	"github.com/gofiber/fiber/v2"
)

func main() {
	app := fiber.New()

	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("Hello, World from :" + os.Getenv("APP_NAME"))
	})

	app.Get("/test", func(c *fiber.Ctx) error {
		return c.SendString("Hello, Test!")
	})

	app.Listen(":3000")
}
