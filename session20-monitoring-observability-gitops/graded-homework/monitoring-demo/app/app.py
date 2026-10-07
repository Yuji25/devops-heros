from flask import Flask, jsonify, Response
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

REQUESTS = Counter(
    "lecture20_http_requests_total",
    "Total HTTP requests received by the Lecture 20 application",
    ["endpoint"]
)

@app.route("/")
def home():
    REQUESTS.labels(endpoint="/").inc()
    return "Lecture 20 Monitoring Demo\n"

@app.route("/health")
def health():
    REQUESTS.labels(endpoint="/health").inc()
    return jsonify(status="healthy")

@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
