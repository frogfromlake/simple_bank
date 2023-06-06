package metrics

import (
	"net/http"
	"strconv"
	"time"
)

type ResponseWriter struct {
    http.ResponseWriter
    status int
    size   int
}

func NewResponseWriter(w http.ResponseWriter) *ResponseWriter {
    return &ResponseWriter{ResponseWriter: w}
}

func (rw *ResponseWriter) WriteHeader(status int) {
    rw.ResponseWriter.WriteHeader(status)
    rw.status = status
}

func (rw *ResponseWriter) Write(b []byte) (int, error) {
    size, err := rw.ResponseWriter.Write(b)
    rw.size += size
    return size, err
}

func PrometheusMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rw := NewResponseWriter(w)
		start := time.Now()
		next.ServeHTTP(rw, r)
		duration := time.Since(start)
		status := strconv.Itoa(rw.status)
		method := r.Method
		endpoint := r.URL.Path
		httpRequestsTotal.WithLabelValues(method, endpoint, status).Inc()
		httpDuration.WithLabelValues(method, endpoint, status).Observe(duration.Seconds())
		httpSize.WithLabelValues(method, endpoint, status).Observe(float64(rw.size))
	})
}
