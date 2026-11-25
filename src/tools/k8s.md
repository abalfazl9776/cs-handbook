// Check network connectivity from inside a pod
nc -zv <service-name> <port>
nc -zv redis-service 6379

curl -v --connect-timeout 5 telnet://my-service:8080

timeout 5 bash -c '</dev/tcp/my-service/8080' && echo "Connected" || echo "Failed"