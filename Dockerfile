# ==========================
# Build stage
# ==========================

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build-env
LABEL stage=build-env
WORKDIR /app

#################################
# Copy source
#################################

COPY Directory.Packages.props .
COPY ./src/ ./
ARG GIT_COMMIT
ARG GIT_BRANCH
#################################
# Restore all dependencies
#################################

RUN dotnet restore /app/Web/Grand.Web/Grand.Web.csproj
#################################
# Build application
#################################

RUN dotnet build \
    /app/Web/Grand.Web/Grand.Web.csproj \
    -c Release \
    --no-restore \
    -p:SourceRevisionId=$GIT_COMMIT \
    -p:GitBranch=$GIT_BRANCH

#################################
# Publish application
#################################

RUN dotnet publish \
    /app/Web/Grand.Web/Grand.Web.csproj \
    -c Release \
    -o /app/publish \
    --no-restore \
    -p:SourceRevisionId=$GIT_COMMIT \
    -p:GitBranch=$GIT_BRANCH

# ==========================
# Runtime stage
# ==========================

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
EXPOSE 8080
COPY --from=build-env /app/publish .

#################################
# Permissions
#################################

RUN chown -R app:app /app
USER app

ENTRYPOINT ["dotnet","Grand.Web.dll"]
