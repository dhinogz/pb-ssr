# # Stage 1: Install templ and generate templ go files
FROM golang:alpine AS templ-generator
WORKDIR /app
RUN apk add --no-cache git
RUN go install github.com/a-h/templ/cmd/templ@latest
COPY . .
RUN templ generate

# Stage 2: Build CSS
FROM node:10-alpine AS css-builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY --from=templ-generator /app ./
RUN npm run tailwindcss -- -m -i ./assets/tailwind.css -o ./assets/dist/styles.min.css

# Stage 3: Build the Go application
FROM golang:alpine AS go-builder
WORKDIR /app
RUN apk add --no-cache git
COPY go.mod go.sum ./
RUN go mod download
RUN go mod verify
COPY --from=templ-generator /app ./
COPY --from=css-builder /app/assets/dist ./assets/dist
RUN go generate ./...
RUN go build -ldflags="-s -w" -o ptht

# Stage 4: Final stage
FROM gcr.io/distroless/static
COPY --from=go-builder /app/ptht /ptht
EXPOSE 8080
ENTRYPOINT ["/ptht", "serve", "--http=0.0.0.0:8090"]
