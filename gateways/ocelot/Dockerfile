FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy project files and restore dependencies
COPY . .
RUN dotnet restore

RUN dotnet publish -c Release -o /out

# Use runtime image for final container
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app

# Copy the built app
COPY --from=build /out .

# Expose port 80 and run
EXPOSE 80
CMD ["dotnet", "ocelot-gw.dll"]