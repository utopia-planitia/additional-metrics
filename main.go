package main

import (
	"bytes"
	"fmt"
	"log"
	"net/http"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	_ = promauto.NewGaugeFunc(prometheus.GaugeOpts{
		Name: "iptables_most_duplicated_rule_count",
		Help: "The count of the most duplicated iptable rule.",
	}, func() float64 {
		return float64(iptablesMostDuplicatedRuleTotal())
	})

	executionTime = promauto.NewCounter(prometheus.CounterOpts{
		Name: "iptables_most_duplicated_rule_count_execution_time_total_ms",
		Help: "The total execution time in milliseconds.",
	})
)

func main() {

	http.Handle("/metrics", promhttp.Handler())

	c := iptablesMostDuplicatedRuleTotal()

	if c == -1 {
		log.Fatalf("failed to receive metrics value")
	}

	log.Printf("iptables_most_duplicated_rule_total %d", c)

	log.Printf("listening on port :2112")

	err := http.ListenAndServe(":2112", nil)
	if err != nil {
		log.Fatalf("failed to listen and serve: %v", err)
	}
}

func iptablesMostDuplicatedRuleTotal() int64 {
	beginning := time.Now()
	defer func() {
		delta := time.Since(beginning).Milliseconds()
		log.Printf("script exection took %dms", delta)
		executionTime.Add(float64(delta))
	}()

	cmd := exec.Command("bash", "./iptables-metric.sh")
	stderr := &bytes.Buffer{}
	cmd.Stderr = stderr

	out, err := cmd.Output()
	if err != nil {
		fmt.Print(stderr.String())
		log.Printf("failed to execute metrics script: %v", err)
		return -1
	}

	s := strings.TrimSpace(string(out))
	c, err := strconv.ParseInt(s, 10, 0)
	if err != nil {
		log.Printf("failed to parse output to int: %v: %s", err, s)
		return -1
	}

	return c
}
