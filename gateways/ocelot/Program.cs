using Ocelot.DependencyInjection;
using Ocelot.Middleware;

var builder = WebApplication.CreateBuilder(args);

// Load Ocelot configuration
builder.Configuration.AddJsonFile("ocelot.json");

// Add Ocelot services
builder.Services.AddOcelot();

var app = builder.Build();

app.UseOcelot().Wait();

app.Run();