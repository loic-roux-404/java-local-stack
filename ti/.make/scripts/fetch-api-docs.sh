#!/usr/bin/env bash

mkdir ~/Postman || true

CONFIG_FILE=$1

if [ -z "$CONFIG_FILE" ]; then
    echo "Usage: $0 prefix-chart-configmap/config/local/application-prefix-local.yml"
    exit 1
fi

curl_get() {
    curl $1 -H 'Accept: application/json, */*; q=0.01' \
        -H 'Content-Type: application/json; charset=utf-8'
}

SERVICES=$(yq '.spring.cloud.discovery.client.simple.instances | keys | .[]' $CONFIG_FILE)

echo "Services: $(echo $SERVICES | xargs)"

for service in $(yq '.spring.cloud.discovery.client.simple.instances | keys | .[]' $CONFIG_FILE); do \

	HOST=$(yq ".spring.cloud.discovery.client.simple.instances.[\"$service\"][0].uri" "$CONFIG_FILE");
    URL_NEW=$(printf "%s/v3/api-docs" $HOST);
    URL=$(printf "%s/v2/api-docs" $HOST);

    echo "Fetching API docs for $URL";
    curl_get $URL > ~/Postman/$service.json;
    if grep -q "NOT_FOUND" ~/Postman/$service.json; then
        echo "Fallback fetch API docs for $URL_NEW";
        curl -Ls $URL_NEW > ~/Postman/$service.json;
    fi
    sed -i "s/Trusted Interactions APIs/$service/g" ~/Postman/$service.json
    sed -i 's/"host"/"schemes":["http"],"host"/g' ~/Postman/$service.json
    sed -i "s|\"url\":\"$HOST\"|\"url\":\"http://localhost:8000/api\"|g" ~/Postman/$service.json
done

cat << EOF > ~/Postman/ti-local-env.json
{
	"name": "Ti local",
	"values": [
		{
			"key": "apiKey",
			"value": "",
			"type": "any",
			"enabled": true
		}
	]
}
EOF
