docker run -d --name grafana -p 3000:3000 -e GF_INSTALL_PLUGINS="frser-sqlserver-datasource" grafana/grafana:12.0.0
