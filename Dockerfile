# ==========================
# Build stage
# ==========================

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build-env

LABEL stage=build-env

WORKDIR /app


COPY Directory.Packages.props .

COPY ./src/ ./



ARG GIT_COMMIT
ARG GIT_BRANCH



# Restore dependencies
RUN dotnet restore /app/Web/Grand.Web/Grand.Web.csproj



# Build modules
RUN for module in /app/Modules/*; do \
    dotnet build "$module" \
    -c Release \
    --no-restore \
    -p:SourceRevisionId=$GIT_COMMIT \
    -p:GitBranch=$GIT_BRANCH; \
done



# Build plugins
RUN for plugin in /app/Plugins/*; do \
    dotnet build "$plugin" \
    -c Release \
    --no-restore \
    -p:SourceRevisionId=$GIT_COMMIT \
    -p:GitBranch=$GIT_BRANCH; \
done



# Publish application

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



# IMPORTANT
# Verify dependencies exist

RUN ls -la /app | grep AutoMapper || true



RUN chown -R app:app /app


USER app



ENTRYPOINT ["dotnet","Grand.Web.dll"]
