# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy project files and restore dependencies
COPY ["AcademiaNovit/AcademiaNovit.csproj", "AcademiaNovit/"]
RUN dotnet restore "AcademiaNovit/AcademiaNovit.csproj"

# Copy the rest of the files
COPY . .

# Publish the application
RUN dotnet publish "AcademiaNovit/AcademiaNovit.csproj" -c Release -o /app/publish \
    --no-restore \
    -p:UseAppHost=false

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

# Install runtime dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgdiplus \
        libc6-dev \
        libx11-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy published files
COPY --from=build /app/publish .

# Expose port 80
EXPOSE 80

# Configure environment variables
ENV ASPNETCORE_URLS=http://+:80 \
    ASPNETCORE_ENVIRONMENT=Production

# Set the entry point
ENTRYPOINT ["dotnet", "AcademiaNovit.dll"]
