#!/bin/sh

ELASTICSEARCH_URL="${ELASTICSEARCH_URL:-http://elasticsearch:9200}"
COMPANIES=${COMPANIES:-worldline}
ELASTICSEARCH_TEMPLATE_CREATE_ROUTE="${ELASTICSEARCH_TEMPLATE_CREATE_ROUTE:-_template}"

echo "Set up elasticsearch at $ELASTICSEARCH_URL"

echo "Create abc template"
curl -X PUT "$ELASTICSEARCH_URL/$ELASTICSEARCH_TEMPLATE_CREATE_ROUTE/abc" \
  -H "Content-Type: application/json" --data-binary "@$ELASTICSEARCH_abc_TPL"
echo

echo "Create cust_abc template"
curl -X PUT "$ELASTICSEARCH_URL/$ELASTICSEARCH_TEMPLATE_CREATE_ROUTE/cust_abc" \
  -H "Content-Type: application/json" --data-binary "@$ELASTICSEARCH_CUST_abc_TPL"
echo

echo "Create demand template"
curl -X PUT "$ELASTICSEARCH_URL/$ELASTICSEARCH_TEMPLATE_CREATE_ROUTE/demand" \
  -H "Content-Type: application/json" --data-binary "@$ELASTICSEARCH_DEMAND_TPL"
echo

echo "Create audit template"
curl -X PUT "$ELASTICSEARCH_URL/$ELASTICSEARCH_TEMPLATE_CREATE_ROUTE/audit" \
  -H "Content-Type: application/json" --data-binary "@$ELASTICSEARCH_AUDIT_TPL"
echo

echo "Create event template"
curl -X PUT "$ELASTICSEARCH_URL/$ELASTICSEARCH_TEMPLATE_CREATE_ROUTE/event" \
  -H "Content-Type: application/json" --data-binary "@$ELASTICSEARCH_EVENT_TPL"
echo

echo "Create cix template"
curl -X PUT "$ELASTICSEARCH_URL/$ELASTICSEARCH_TEMPLATE_CREATE_ROUTE/cix" \
  -H "Content-Type: application/json" --data-binary "@$ELASTICSEARCH_ARCHIVING_TPL"
echo
## Create indexes

echo "Create abc index"
curl -X PUT $ELASTICSEARCH_URL/abc || true
echo
echo "Create demand index"
curl -X PUT $ELASTICSEARCH_URL/demand || true

echo "Create audit index"
curl -X PUT $ELASTICSEARCH_URL/audit || true


IFS=','; for COMPANY in $COMPANIES; do
  echo "Create abc-$COMPANY index"
  curl -X PUT $ELASTICSEARCH_URL/abc-$COMPANY || true
  echo
  echo "Create demand-$COMPANY index"
  curl -X PUT $ELASTICSEARCH_URL/demand-$COMPANY || true
  echo
  echo "Create audit-$COMPANY index"
  curl -X PUT $ELASTICSEARCH_URL/audit-$COMPANY || true
  echo
done

unset IFS

echo "Create cust_abc index"
cat $ELASTICSEARCH_CUST_abc_TPL | jq -r '.template' > /tmp/cust_abc_template.json
curl -X PUT "$ELASTICSEARCH_URL/cust_abc"  -H "Content-Type: application/json"
echo
for i in $(seq 0 9); do
  echo "Create cust_abc_$i index"
  curl -X PUT "$ELASTICSEARCH_URL/cust_abc_$i"
  echo
done
