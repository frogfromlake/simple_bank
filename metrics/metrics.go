package metrics

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
)

var (
	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests.",
		},
		[]string{"method", "endpoint", "status"},
	)
	httpDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_duration_seconds",
			Help:    "Duration of HTTP requests.",
			Buckets: []float64{0.1, 0.3, 1.2, 5.0},
		},
		[]string{"method", "endpoint", "status"},
	)
	httpSize = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_size_bytes",
			Help:    "Size of HTTP responses.",
			Buckets: []float64{100, 500, 1000, 5000, 10000},
		},
		[]string{"method", "endpoint", "status"},
	)
)

func HelloHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Hello, world!"))
}

func PingHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("pong"))
}

func init() {
	prometheus.MustRegister(httpRequestsTotal)
	prometheus.MustRegister(httpDuration)
	prometheus.MustRegister(httpSize)
}
