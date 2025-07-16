#############
# Make config
#############

SHELL:=/usr/bin/env bash
MAKE:=$(MAKE) --no-print-directory

.SUFFIXES:
MAKEFLAGS += --no-builtin-rules --no-builtin-variables

, :=,
open_parenthesis:=(
close_parenthesis:=)
space := $(subst ,, )
ARGS:=

#########
# Options
#########

include .env
export

CLIENT_NAME?=$(patsubst pictet-%-meta,%,$(notdir $(CURDIR)))
IS_PRODUCT?=
LOG_LEVEL?=DEBUG
GIT_CLONE_REPOS?=
TZ?=Europe/Paris
MOCK_TARGET?=
MOCK_START_CMD?=
INCLUDE?=
EXCLUDE?=
JDEBUG?=
DUMP_SQL?=
TI_MAX_HEADER_SIZE?=102400
JAVA_HOME_LS?=$(JAVA_HOME)
JIT_SERVER?=
PROXY_HOST?=127.0.0.1
PROXY_PORT?=
MITMPROXY?=
REMOTE_MYSQL_USER?=root
REMOTE_MYSQL_PASSWORD?=root
REMOTE_MYSQL_HOST?=localhost
REMOTE_MYSQL_PORT?=3306
LOG:=1>app.log 2> app.log &
MVN_SETTINGS?=$(HOME)/.m2/settings.xml
PRIOR_INSTALL_TARGETS?=

# Apisix
APISIX_PROFILES?=apisix-adv
APISIX_ADMIN_ROUTES_YAML?=pictet-service-apisix/conf/apisix-admin.yaml
APISIX_CUST_ROUTES_YAML?=pictet-service-apisix/conf/apisix-cust.yaml
TI_SERVICE_APISIX_VERSION?=8.3.1

export JDEBUG
export INCLUDE
export EXCLUDE
export JAVA_HOME_LS
export REMOTE_MYSQL_USER
export REMOTE_MYSQL_PASSWORD
export REMOTE_MYSQL_HOST
export REMOTE_MYSQL_PORT
export APISIX_PROFILES
export LIBREOFFICE_PATH

#######################
# java services targets
#######################

# Get the list of service directories that contain pom.xml
find_svc_cmd=find . -mindepth 3 -maxdepth 3 -name 'pom.xml' -exec dirname {} \; | grep -E 'service$$'

SERVICES:=$(subst ./,,$(shell $(find_svc_cmd)$(if $(EXCLUDE), | grep -v '$(EXCLUDE)')$(if $(INCLUDE), | \
  grep -E '$(INCLUDE)')))
SERVICES+= $(shell find . -mindepth 2 -maxdepth 2 -name 'pom.xml' -exec dirname {} \; | grep -E 'batch$$' \
  $(if $(EXCLUDE), | grep -v '$(EXCLUDE)')$(if $(INCLUDE), | grep -E '$(INCLUDE)'))

WEB_TARGETS:=$(shell find . -mindepth 2 -maxdepth 2 -name 'ember-cli-build.js' -exec dirname {} \;$(if $(EXCLUDE), | grep -v '$(EXCLUDE)')\
  $(if $(INCLUDE), | grep -E '$(INCLUDE)'))
WEB_TARGETS:=$(subst ./,,$(filter %-application,$(WEB_TARGETS)))

ALL_SERVICES:=$(SERVICES)
ALL_SERVICES:=$(strip $(ALL_SERVICES))

INSTALLABLE:=$(subst ./,,$(shell find . -mindepth 2 -maxdepth 2 -name 'pom.xml' -exec dirname {} \; | grep -Ev '(pictet|ticust)-(service|lib)'\
	$(if $(INCLUDE), | grep -E '$(INCLUDE)';)\
))
PRODUCT_REPOS:=$(subst ./,,$(shell find . -mindepth 2 -maxdepth 2 -name 'pom.xml' -exec dirname {} \; | grep -E '(pictet|ticust)-(service|lib)'\
    $(if $(INCLUDE), | grep -E '$(INCLUDE)';)\
))
PRODUCT_CONTAINERS:=$(subst ./,,$(shell find . -mindepth 2 -maxdepth 2 -name 'Dockerfile' -exec dirname {} \;))
ALL_CONTAINERS:=$(PRODUCT_CONTAINERS) $(shell find . -name 'Dockerfile' -exec dirname {} \;)

ifdef IS_PRODUCT
INSTALLABLE:=$(PRODUCT_REPOS)
PRODUCT_REPOS:=
endif

INSTALL_PRODUCT_REPOS:=$(addprefix install.,$(PRODUCT_REPOS))
INSTALL_CUSTOMER_REPOS:=$(addprefix install.,$(INSTALLABLE))
INSTALL_PRODUCT_CONTAINERS:=$(addprefix install.,$(PRODUCT_CONTAINERS))
THREADS?=$(words $(ALL_SERVICES))

########################
# Computed java jvm args
########################

SPRING_PERF_ARGS:=-Dspring.jmx.enabled=false -Dspring.cloud.config.enabled=false -Dcom.sun.management.jmxremote=false
SPRING_PERF_ARGS+= -Dspring.application.admin.enabled=false -DSpring.liveBeansView.mbeanDomain=false -Dspring.main.banner-mode=OFF
RESOURCE_ARGS:= $(SPRING_PERF_ARGS) -XX:+UseSerialGC -XX:MaxMetaspaceSize=64m -Xverify:none -XX:TieredStopAtLevel=1 -XX:-TieredCompilation
RESOURCE_ARGS+= -XX:GCTimeRatio=15 -Dserver.connection-timeout=40s -XX:AdaptiveSizePolicyWeight=90 -XX:+UseStringDeduplication
RESOURCE_ARGS+= -XX:+UseCompressedOops -XX:+OptimizeStringConcat -XX:+UseStringCache
SHARED_CLASSES_ARGS:= -Xshareclasses:name=shared-classes,cacheDirPerm=1777,groupAccess -XX:SharedCacheHardLimit=4096m
OPENJ9_ARGS?= -XX:+EnableCRIUSupport -XX:-CRIUSecProvider -Xquickstart -Xtune:virtualized -XX:+IdleTuningGcOnIdle $(SHARED_CLASSES_ARGS)

ifdef JIT_SERVER
JIT_OPTIONS:= -XX:+UseJITServer -XX:JITServerAddress=localhost:38400
OPENJ9_ARGS+=$(JIT_OPTIONS)
endif

export OPENJ9_ARGS

TEST_ARGS:= $(RESOURCE_ARGS) $(OPENJ9_ARGS) -Dserver.tomcat.threads.max=2 -Dlog4j.logger.com.ewl=$(LOG_LEVEL) -Dspring.main.lazy-initialization=true

# For IDE
ifdef OPENJ9_ARGS
TEST_ARGS+= -XX:+CRIURestoreNonPortableMode
ALL_PERF_ARGS:= -Xms256m -Xmx256m $(OPENJ9_ARGS) -Dserver.tomcat.max-connections=10
endif

JSON_TEST_ARGS:=$(subst $(space)-,\"$(,)\"-,$(TEST_ARGS))

MAIN_CLASS:=com.pictet.data.parent.service.StartBoot
START_BOOT:= -Dspring-boot.run.mainClass=$(MAIN_CLASS)

SPRING_ARGS?=
SHARED_SPRING_ARGS?=

SHARED_SPRING_ARGS+= -Dspring.profiles.active=$(INCLUDE_PROFILES)
SHARED_SPRING_ARGS+= -Dauthentication.jwt.secret=$(JWT_SECRET)
SHARED_SPRING_ARGS+= $(PROXY_ARGS)
SHARED_SPRING_ARGS+= -Dti.server.max-http-header-size=$(TI_MAX_HEADER_SIZE) -Dserver.max-http-header-size=$(TI_MAX_HEADER_SIZE)
SHARED_SPRING_ARGS+= -Dspring.config.additional-location=$(SPRING_ADDITIONAL_CONFIG),file:$(PWD)/.cnf/application-local.yml

ifdef PROXY_PORT
MITMPROXY:=mitmproxy
SHARED_SPRING_ARGS+= -Dhttp.proxyHost=$(PROXY_HOST) -Dhttp.proxyPort=$(PROXY_PORT) -Djava.net.useSystemProxies=true
endif

SPRING_ARGS+= $(RESOURCE_ARGS) $(OPENJ9_ARGS) -Xms128m -Xmx128m -Dserver.tomcat.max-connections=15 -Dserver.tomcat.threads.max=2
SPRING_ARGS+= $(SHARED_SPRING_ARGS)

SPRING_ARGS+= -Dlog4j.logger.com.pictet=$(LOG_LEVEL)
SPRING_ARGS+= -Dti.mysql.user=$(MYSQL_USER) -Dti.mysql.server=$(MYSQL_HOST):$(MYSQL_PORT) -Dti.mysql.password=$(MYSQL_PASSWORD) -Dti.mysql.serverTimezone=$(TZ)
SPRING_ARGS+= -Drouting.antivirus.checkMessage=$(ENABLE_CLAMAV) -Drouting.antivirus.checkParts=$(ENABLE_CLAMAV)
SPRING_ARGS+= -Dantivirus.clamav.enabled=$(ENABLE_CLAMAV) -Dantivirus.clamav.host=localhost -Dantivirus.clamav.port=3310

ifdef DUMP_SQL
SPRING_ARGS+= -Dspring.jpa.show-sql=true -Dspring.jpa.properties.hibernate.format_sql=true
endif

DEBUGGER_PARAMS:= transport=dt_socket,server=y
DEBUGGER_ARGS:= -Djava.compiler=NONE

configure_debug:=
ifeq ($(JDEBUG),true)
define configure_debug
	@echo "Configuring debug for service $(1)"
	$(eval DEBUGGER_FULL_PARAMS:= $(DEBUGGER_ARGS) -agentlib:jdwp=$(DEBUGGER_PARAMS)$(,)suspend=n$(,)address="1$(strip $(1))")
	$(eval TEST_DEBUGGER:= $(DEBUGGER_ARGS) -Xrunjdwp:$(DEBUGGER_PARAMS)$(,)suspend=y$(,)address="2$(strip $(1))")
endef
endif

##################
### Help Target
##################

help:
	@echo "--------- HELP for $(CLIENT_NAME) -----------"
	@echo ".env file should be automaticly generated for your customer with nix"
	@echo "$(THREADS) threads for services"
	@echo "--------- SETUP -----------"
	@echo "Before starting any service do : make install"
	@echo "--------- SCRIPTS -----------"
	@echo "Custom scripts : $(CUSTOM_SCRIPTS)"
	@echo "--------- DOCKER DAEMONS -----------"
	@echo "make daemons"
	@echo "Single daemon : make COMPOSE_PROFILES=mysql daemons"
	@echo "Daemons (docker compose) : make daemons"
	@echo "Daemons stop : make daemons-stop"
	@echo "--------- Services -----------"
	@echo "Mutliple services : make ./pictet-$(CLIENT_NAME)-service-your-svc/your-service ./pictet-$(CLIENT_NAME)-service-your-svc/your-service2 -j2"
	@echo "daemons / Multiple services : make INCLUDE='pictet-..*(abc|efg)' all -j3"
	@echo "--------- Services Health -----------"
	@echo "make status / add VV=true to see down services"
	@echo "--------- Test -----------"
	@echo "make JDEBUG= test.pictet-$(CLIENT_NAME)-service-your-svc ARGS=-Dtest='ProcessExecutorIntegrationTest'"
	@echo "--------- Log -----------"
	@echo "make log.pictet-$(CLIENT_NAME)-service-your-svc"
	@echo "make log-all-services"
	@echo "--------- Kill -----------"
	@echo "make kill.pictet-$(CLIENT_NAME)-service-your-svc"
	@echo "make kill-all-services"
	@echo "--------- Restart -----------"
	@echo "make restart.pictet-$(CLIENT_NAME)-service-your-svc"
	@echo "make restart-all-services"
	@echo "-------------- UI -------------------"
	@echo "$(WEB_TARGETS)"
	@echo "-------------- CUSTOMER REPOS -------------------"
	@echo "$(INSTALLABLE)"
	@echo "-------------- PRODUCT CONTAINERS -------------------"
	@echo "$(INSTALL_PRODUCT_CONTAINERS)"
	@echo "-------------- MOCK -------------------"
	@echo "$(MOCK_TARGET)"
	@echo "--------- VM ARGS -------------------"
	@echo "$(SPRING_ARGS)"

#########
### Utils
#########

sleep-10:
	@sleep 10

###################
### Install Targets
###################

repo-clone:
	@for repo in $(GIT_CLONE_REPOS); do \
		git clone $$repo || true; \
	done

define add_host
	@echo "Adding host $(1) to $(2) ..."
	@grep -q "$(1)" $(2) || echo "$(1) 127.0.0.1" | sudo tee -a $(2) > /dev/null || true
endef

install-misc:
	@echo "Setting up hosts"
	@$(call add_host,identityprovider,/etc/hosts)
	@$(call add_host,devbox,/etc/hosts)
	@keytool -delete -alias replserver -keystore $(HOME)/keystore.jks -storepass password || true
	@keytool -genkey -alias replserver \
	  -keyalg RSA -keystore $(HOME)/keystore.jks \
	  -dname "CN=Bill Smith, OU=Worldline, O=Wln, L=Lyon, S=RHONE, C=FR" \
	  -storepass password -keypass password

define mvn_install_full_cmd
	mvn -fn clean plugin:descriptor resources:resources generate-sources \
	  compiler:compile jar:jar plugin:addPluginArtifactMetadata install:install \
	  -Dcheckstyle.skip -DargLine="$(TEST_ARGS)" $(ARGS);
endef

$(INSTALL_PRODUCT_REPOS):
	@$(eval FOLDER:=$(subst install.,,$@))
	@echo "Installing $(FOLDER) to $(PRODUCT_VERSION)"
	@cd $(FOLDER) && git add . && git stash && git checkout $(PRODUCT_GIT_VERSION); \
      mvn -fn versions:update-parent "-DgenerateBackupPoms=false -DparentVersion=$(PRODUCT_PARENT_VERSION)" || true && \
	  mvn -fn versions:set -DgenerateBackupPoms=false -DnewVersion=$(PRODUCT_VERSION) && \
	  $(call mvn_install_full_cmd)

$(INSTALL_PRODUCT_CONTAINERS):
	@$(eval FOLDER:=$(subst install.,,$@))
	@$(eval SERVICE_SHORTNAME:=$(shell echo "$(FOLDER)" | cut -d'/' -f1 | tr a-z A-Z | tr '-' '_'))
	@$(eval SERVICE_VERSION:=$(value $(SERVICE_SHORTNAME)_VERSION))
	@echo "Pin $(FOLDER) version to $(SERVICE_VERSION)"
	@cd $(FOLDER) && git add . && git stash && git checkout $(SERVICE_VERSION);

$(INSTALL_CUSTOMER_REPOS):
	@$(eval FOLDER:=$(subst install.,,$@))
	@echo "Installing dependencies of $(FOLDER)";
	@cd $(FOLDER) && $(call mvn_install_full_cmd)

mvn-install: $(PRIOR_INSTALL_TARGETS)
	@$(MAKE) $(INSTALL_CUSTOMER_REPOS) -j$(THREADS) ARGS=$(ARGS)

INSTALL_WEB_TARGETS:=$(addprefix install.,$(WEB_TARGETS))

$(INSTALL_WEB_TARGETS):
	@$(eval FOLDER:=$(subst install.,,$@))
	@cd $(FOLDER) && http_proxy= yarn install --force;

web-install: $(INSTALL_WEB_TARGETS)

##################
### Ide Targets
##################

IDEA_TARGETS:=$(addprefix idea.,$(INSTALLABLE))

$(IDEA_TARGETS):
	@$(eval FOLDER:=$(subst idea.,,$@))
	@$(eval SERVICE_SHORTNAME:=$(shell echo "$(FOLDER)" | cut -d'/' -f1 | tr a-z A-Z | tr '-' '_'))
	@$(eval APP_ARGS:=$(value $(SERVICE_SHORTNAME)_ARGS))
	@cd $(FOLDER); source docker/service.env; \
		SERVICE_FOLDER=$$(find . -type d -name '*-service' | cut -c 3-); \
		SERVICE_FOLDER=$${SERVICE_FOLDER:-$$service}; \
		echo "Installing config for $$service/$$SERVICE_FOLDER"; \
		mkdir -p .run/; \
		touch .run/$$SERVICE_FOLDER.run.xml && cat ../.make/ide/Service.run.xml | sed "s|%ALTERNATIVE_JRE_PATH%|$$JAVA_HOME|g" | \
		  sed "s|%SPRING_ARGS%|$(SPRING_ARGS) $(APP_ARGS)|g" | \
		  sed "s|%service%|$$SERVICE_FOLDER|g" | tee .run/$$SERVICE_FOLDER.run.xml; \
		touch .run/$$SERVICE_FOLDER.attach.run.xml && cat ../.make/ide/Attach.run.xml | \
		  sed "s|%service%|$$SERVICE_FOLDER|g" | sed "s|%port%|1$$SERVICE_PORT|g" | \
		  tee .run/$$SERVICE_FOLDER.attach.run.xml;

idea-configs: $(IDEA_TARGETS)

VSCODE_WEB_TARGETS:=$(addprefix vscode.,$(WEB_TARGETS))

$(VSCODE_WEB_TARGETS):
	@$(eval FOLDER:=$(subst vscode.,,$@))
	@$(eval SERVICE_PORT:=$(if $(filter ticust%,$(FOLDER)),4250,4200))
	@mkdir -p $(FOLDER)/.vscode/ && cat .make/ide/launch-chrome.json |\
		sed 's/%module_prefix%/$(FOLDER)/g' | sed 's/%SERVICE_PORT%/$(SERVICE_PORT)/g' | \
		tee $(FOLDER)/.vscode/launch.json
	@cp -r .make/ide/web/* $(FOLDER)/.vscode/ && cp .make/ide/database-client-config.json $(FOLDER)/.vscode/;

JAVA_SHORT_VERSION:=$(shell java -version 2>&1 | head -n 1 | awk -F '"' '{print $$2}' | cut -d. -f 1,2 | sed 's/\.0//g')

vs_settings_tpl=\
	sed "s|%JAVA_HOME%|$(JAVA_HOME)|g" | \
	  sed "s|%JAVA_HOME_LS%|$(JAVA_HOME_LS)|g" | sed "s|%JSON_TEST_ARGS%|$(JSON_TEST_ARGS)|g" | sed "s|%MVN_SETTINGS%|$(MVN_SETTINGS)|g" | \
	  sed "s|%VM_ARGS%|$(ALL_PERF_ARGS)|g" | sed "s|%JAVA_SHORT_VERSION%|$(JAVA_SHORT_VERSION)|g"

VSCODE_TARGETS:=$(addprefix vscode.,$(INSTALLABLE))

$(VSCODE_TARGETS):
	@$(eval FOLDER:=$(subst vscode.,,$@))
	@$(eval SERVICE_SHORTNAME:=$(shell echo "$(FOLDER)" | cut -d'/' -f1 | tr a-z A-Z | tr '-' '_'))
	@$(eval APP_ARGS:=$(value $(SERVICE_SHORTNAME)_ARGS))
	@cd $(FOLDER); source docker/service.env; \
		SERVICE_FOLDER=$$(find . -maxdepth 1 -type d -name '*-service' | cut -c 3-); \
		SERVICE_FOLDER=$${SERVICE_FOLDER:-$$service}; \
		echo "Installing config for $(FOLDER)/$$SERVICE_FOLDER"; \
		mkdir -p .{vscode,settings}/; \
		cat ../.make/ide/settings.json | $(vs_settings_tpl) | tee .vscode/settings.json; \
		touch .vscode/launch.json;\
		cat ../.make/ide/launch.json | sed "s|%service%|$$SERVICE_FOLDER|g" | \
			sed "s|%SPRING_ARGS%|$(SPRING_ARGS) $(APP_ARGS)|g" | sed "s|%PWD%|$(PWD)|g" | \
			sed "s|%SERVICE_PORT%|$$SERVICE_PORT|g" | \
			sed "s|%MAIN_CLASS%|$(MAIN_CLASS)|g" | tee .vscode/launch.json; \
		cp ../.make/ide/extensions.json .vscode/; \
		cp ../.make/ide/database-client-config.json .vscode/; \
		mkdir .settings/ || true && \
		  echo "org.eclipse.jdt.core.compiler.problem.missingSerialVersion=warn" > .settings/org.eclipse.jdt.core.prefs;

generate-vscode-workspace:
	@echo "{\"folders\": [], \"settings\": $$(cat .make/ide/settings.json | $(vs_settings_tpl))}" | jq '.' > pictet-$(CLIENT_NAME).code-workspace
	@for service in $(INSTALLABLE); do \
		jq --arg path "$$service" '.folders += [{"path": $$path}]' pictet-$(CLIENT_NAME).code-workspace > tmp.$$.json && \
		  mv tmp.$$.json pictet-$(CLIENT_NAME).code-workspace; \
	done

vscode-configs: $(VSCODE_TARGETS) $(VSCODE_WEB_TARGETS)

######################
### All install target
######################

install: install-misc repo-clone web-install mvn-install-product mvn-install

##################
### Daemon targets
##################

daemons:
	@echo "Starting daemons ..."
	@mkdir -p ~/.cache/javasharedresources/ || true
	@sudo chown -R $(USER):$(USER) ~/.cache/javasharedresources/ && \
	  sudo chmod -R 777 ~/.cache/javasharedresources/
	@COMPOSE_PROFILES=$(COMPOSE_PROFILES),$(APISIX_PROFILES) docker compose up -d $(1)

daemons-ps:
	@docker compose ps $(1)

daemons-stop:
	@echo "Stopping daemons ..."
	@docker compose down $(1)

######################
# Mock target
######################

KILL_MOCK_TARGET:=kill.$(MOCK_TARGET)
LOG_MOCK_TARGET:=log.$(MOCK_TARGET)
RESTART_MOCK_TARGET:=restart.$(MOCK_TARGET)

$(MOCK_TARGET):
	@cd $@ && nohup $(MOCK_START_CMD) $(LOG)
	@echo "$@ is now starting"

$(KILL_MOCK_TARGET):
	@$(eval FOLDER:=$(subst kill.,,$@))
	@$(eval include $(FOLDER)/docker/service.env)
	@$(call kill_port_in,$(SERVICE_PORT))
	@echo "Killed service in directory $(FOLDER)"

$(RESTART_MOCK_TARGET): $(KILL_MOCK_TARGET) $(MOCK_TARGET)

###################
### Service targets
###################

ifdef PROXY_PORT
export http_proxy=$(PROXY_HOST):$(PROXY_PORT)
endif

$(WEB_TARGETS):
	$(eval PREFIX:=$(shell echo "$@" | cut -d'/' -f1))
	@echo "$@ is now starting"

$(ALL_SERVICES):
	@$(eval include $@/docker/service.env)
	@$(eval include $@/../docker/service.env)
	@$(eval SERVICE_SHORTNAME:=$(shell echo "$@" | cut -d'/' -f1 | tr a-z A-Z | tr '-' '_'))
	@$(eval APP_ARGS:=$(value $(SERVICE_SHORTNAME)_ARGS))
	@$(call configure_debug,$(SERVICE_PORT))
	@$(eval ALL_JVM_ARGS:=$(DEBUGGER_FULL_PARAMS) $(SPRING_ARGS) $(START_BOOT) $(APP_ARGS))
	@cd $@ && nohup mvn spring-boot:run -Dmaven.test.skip=true -Dspring-boot.run.jvmArguments="$(ALL_JVM_ARGS)" $(ARGS) $(LOG)
	@echo "$@ is now starting $(if $(APP_ARGS),with $(APP_ARGS),)"

start-all-services:
	@$(MAKE) JDEBUG=$(JDEBUG) $(SERVICES) -j$(THREADS)

###################
### status targets
###################

_SEP="----------------------"
SEP="$(_SEP)$(_SEP)$(_SEP)"
CONFIG_FILE?=pictet$(CLIENT_NAME)-chart-configmap/config/local/application-$(CLIENT_NAME)-local.yml
VV=

status:
	@echo -n $(SEP)
	@for service in $$(yq '.spring.cloud.discovery.client.simple.instances | keys | .[]' $(CONFIG_FILE)); do \
		uri=$$(yq ".spring.cloud.discovery.client.simple.instances.[\"$$service\"][0].uri" "$(CONFIG_FILE)"); \
		res=$$(http_proxy= curl -s "$$uri/health"); echo $$res | grep status &>/dev/null && \
		echo -en "\n[ $$service / $$uri/health ] : $$(echo $$res | yq .status)\n$(SEP) \r" \
		  || echo -en "$(if $(VV),\n[ $$service / $$uri/health ] DOWN\n$(SEP),)"; \
	done

fetch-api-docs:
	@./.make/scripts/fetch-api-docs.sh $(CONFIG_FILE)

####################
### All start target
####################

all: daemons mitmproxy start-all-services $(MOCK_TARGET) $(WEB_TARGETS)

##########################
### Kill & restart Targets
##########################

KILL_TARGETS:=$(subst ./,,$(addprefix kill.,$(ALL_SERVICES)))
RESTART_TARGETS:=$(subst ./,,$(addprefix restart.,$(ALL_SERVICES)))
KILL_WEB_TARGETS:=$(subst ./,,$(addprefix kill.,$(WEB_TARGETS)))
RESTART_WEB_TARGETS:=$(subst ./,,$(addprefix restart.,$(WEB_TARGETS)))

define kill_all_in
@for pid in $$(ps -ef | grep '$(1)' | grep -vE 'grep' | awk '{print $$2}' | tr '\n' ' ' | xargs);\
		do [[ ! -z $$pid ]] && kill $$pid; done;
endef

define kill_port_in
@for pid in $$(ss -ltunp 'sport = :$(1)' | awk '{print $$7}' | awk -F'[=,$(close_parenthesis)]' '{print $$3}' | xargs);\
		do [[ ! -z $$pid ]] && kill $$pid; done;
endef

$(KILL_TARGETS):
	@$(eval FOLDER:=$(subst kill.,,$@))
	@$(eval include $(FOLDER)/docker/service.env)
	@$(eval include $(FOLDER)/../docker/service.env)
	@$(call kill_all_in,maven.multiModuleProjectDirectory=$(PWD)/$(FOLDER))
	@$(call kill_port_in,1$(SERVICE_PORT))
	@echo "Killed service in directory $(FOLDER) on $(SERVICE_PORT)"

$(KILL_WEB_TARGETS):
	@$(eval FOLDER:=$(subst kill.,,$@))
	@$(eval SERVICE_PORT:=$(if $(findstring ticust,$@),4250,4200))
	@$(call kill_port_in,$(SERVICE_PORT))
	@echo "Killed $(FOLDER) on $(SERVICE_PORT)"

kill-all-services:
	@$(MAKE) $(KILL_TARGETS) $(KILL_WEB_TARGETS)

$(RESTART_WEB_TARGETS):
	@$(MAKE) kill.$(subst restart.,,$@)
	@$(MAKE) $(subst restart.,,$@)

$(RESTART_TARGETS):
	@$(MAKE) kill.$(subst restart.,,$@)
	@sleep 10
	@$(MAKE) $(subst restart.,,$@)

#########################
### Kill all with daemons
#########################

down: kill-all-services daemons-stop

################
### Log Targets
################

LOG_TARGETS:=$(subst ./,,$(addprefix log.,$(ALL_SERVICES) $(WEB_TARGETS) $(MOCK_TARGET)))

$(LOG_TARGETS):
	@$(eval FOLDER:=$(subst log.,,$@))
	@if [ -f $(FOLDER)/app.log ]; then tail -500f $(FOLDER)/app.log; fi;

log-all-services:
	@$(MAKE) $(LOG_TARGETS) -j$(words $(LOG_TARGETS))

################
### Test Targets
################

TEST_TARGETS:=$(subst ./,,$(addprefix test.,$(ALL_SERVICES)))

$(TEST_TARGETS):
	@$(eval FOLDER:=$(subst test.,,$@))
	@$(eval include $(FOLDER)/docker/service.env)
	@$(eval include $(FOLDER)/../docker/service.env)
	@$(eval ALL_JVM_ARGS:=$(TEST_ARGS))
	@$(call configure_debug,$(SERVICE_PORT))
	@cd $(FOLDER) && mvn test -DargLine="$(TEST_DEBUGGER) $(ALL_JVM_ARGS)" $(ARGS)

########################
# Shortcut stack targets
########################

SHORTCUT_GOAL:=all
SHORTCUT_EXCLUDE:=ticust|admin

LIGHT?=
CUST?=
CUST_INCLUDE?=..*($(CUST))|pictet-..*(abc)
STATS?=dcr|efg
FULL?=mypictet-..*($(CUST))|..*(abc|dcr|efg|hij|klm|nop|qrs|tuv|wxy)

light:
	@$(MAKE) JDEBUG=false INCLUDE='pictet-..*($(LIGHT))' $(SHORTCUT_GOAL)

kill-light:
	@$(MAKE) INCLUDE='pictet-..*($(LIGHT))' kill-all-services

restart-light: kill-light sleep-10
	@$(MAKE) light SHORTCUT_GOAL=start-all-services

log-light:
	@$(MAKE) INCLUDE='pictet-..*($(LIGHT))' log-all-services

cust:
	@$(MAKE) JDEBUG=false EXCLUDE='external' APISIX_PROFILES=apisix-all \
	  INCLUDE='$(CUST_INCLUDE)' $(SHORTCUT_GOAL)

log-cust:
	@$(MAKE) EXCLUDE='external' INCLUDE='$(CUST_INCLUDE)' log-all-services

kill-cust:
	@$(MAKE) INCLUDE='$(CUST_INCLUDE)' kill-all-services

restart-cust: kill-cust sleep-10
	@$(MAKE) cust SHORTCUT_GOAL=start-all-services

stats:
	@$(MAKE) JDEBUG=false INCLUDE='pictet-..*($(STATS))' $(SHORTCUT_GOAL)

kill-stats:
	@$(MAKE) INCLUDE='pictet-..*($(STATS))' kill-all-services

log-stats:
	@$(MAKE) INCLUDE='pictet-..*($(STATS))' log-all-services

restart-stats: kill-stats sleep-10
	@$(MAKE) stats SHORTCUT_GOAL=start-all-services

full:
	@$(MAKE) JDEBUG=false EXCLUDE='external' APISIX_PROFILES=apisix-all \
	  INCLUDE='$(FULL)' $(SHORTCUT_GOAL)

log-full:
	@$(MAKE) EXCLUDE='external' \
	  INCLUDE='$(FULL)' log-all-services

kill-full:
	@$(MAKE) INCLUDE='$(FULL)' kill-all-services

restart-full: kill-full sleep-10
	@$(MAKE) full SHORTCUT_GOAL=start-all-services

######################
# Other helper targets
######################

MYSQL_CMD:=mysql -h $(MYSQL_HOST) -P $(MYSQL_PORT) -u root -proot --force

MYSQL_DUMP_CMD:=mysqldump -u $(REMOTE_MYSQL_USER) -p'$(REMOTE_MYSQL_PASSWORD)' -h $(REMOTE_MYSQL_HOST) -P $(REMOTE_MYSQL_PORT) \
 --ssl-mode=DISABLED --lock-tables=false --get-server-public-key  --no-tablespaces \
 --complete-insert --skip-triggers --no-create-info --set-gtid-purged=OFF

CUSTOM_SCRIPTS?=$(subst ./,,$(wildcard .make/scripts/*.sh) $(wildcard scripts/*.sh))

$(CUSTOM_SCRIPTS):
	@echo "Running script $@"
	@./$@

enter-db:
	@$(MYSQL_CMD) -D $(1)

run-sql:
	@$(MYSQL_CMD) -D $(1) < $(2)

dump-sql:
	@$(MYSQL_DUMP_CMD) $(1) $(2) | sed '1iRESET MASTER;' | sed '1iSET FOREIGN_KEY_CHECKS=0;' | sed 's/INSERT/REPLACE/g'

pull-table:
	@$(MAKE) dump-sql 1=$(1) 2=$(2) > $(2).sql
	@$(MAKE) run-sql 1=$(1) 2=$(2).sql
	@rm -rf $(2).sql

MITM_LOG:=/tmp/mitmproxy.log

$(MITMPROXY):
	@echo 'Starting mitmproxy on port $(PROXY_PORT)'
	@ss -tuln | grep -q ":$(PROXY_PORT)" && echo -n || nohup mitmweb --listen-port=$(PROXY_PORT) 1> $(MITM_LOG) 2> $(MITM_LOG) &

.PHONY: $(MAKECMDGOALS) $(KILL_TARGETS) $(RESTART_TARGETS) $(LOG_TARGETS) $(ALL_SERVICES) \
  $(INSTALL_PRODUCT_REPOS) $(INSTALL_CUSTOMER_REPOS) $(INSTALL_PRODUCT_CONTAINERS) $(IDEA_TARGETS) \
  $(VSCODE_TARGETS) $(VSCODE_WEB_TARGETS) $(TEST_TARGETS) $(CUSTOM_SCRIPTS) $(MOCK_TARGET) $(KILL_MOCK_TARGET) $(RESTART_MOCK_TARGET) \
  $(WEB_TARGETS) $(KILL_WEB_TARGETS) $(RESTART_WEB_TARGETS) $(MITMPROXY)
