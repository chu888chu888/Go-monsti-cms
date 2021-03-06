GOPATH=$(PWD)/go/
GO=GOPATH=$(GOPATH) go
#GO_COMMON_OPTS=-race
GO_GET=$(GO) get $(GO_COMMON_OPTS)
GO_TEST=$(GO) test $(GO_COMMON_OPTS)

MODULES=daemon httpd data document contactform mail image

ALOHA_VERSION=0.23.2

#DAEMON_VERSION=0.6.1
#DOCUMENT_VERSION=0.3.1
#CONTACTFORM_VERSION=0.3.1
#IMAGE_VERSION=0.3.1
#MAIL_VERSION=0.1.1
#DATA_VERSION=0.1.1
#HTTPD_VERSION=0.1.2

DAEMON_VERSION=master
DOCUMENT_VERSION=master
CONTACTFORM_VERSION=master
IMAGE_VERSION=master
MAIL_VERSION=master
DATA_VERSION=master
HTTPD_VERSION=master

MODULE_PROGRAMS=$(MODULES:%=go/bin/monsti-%)
MODULE_SOURCES=$(MODULES:%=go/src/pkg.monsti.org/monsti-%)

all: monsti bcrypt

monsti: dep-aloha-editor dep-jquery modules templates/master.html

.PHONY: bcrypt
bcrypt: 
	$(GO_GET) pkg.monsti.org/monsti-login/bcrypt

modules: $(MODULES)
$(MODULES): %: go/bin/monsti-%

module/daemon.tar.gz:
	mkdir -p module/
	wget -nv https://gitorious.org/monsti/monsti-daemon/archive-tarball/$(DAEMON_VERSION) -O module/daemon.tar.gz

module/data.tar.gz:
	mkdir -p module/
	wget -nv https://gitorious.org/monsti/monsti-data/archive-tarball/$(DATA_VERSION) -O module/data.tar.gz

module/httpd.tar.gz:
	mkdir -p module/
	wget -nv https://gitorious.org/monsti/monsti-httpd/archive-tarball/$(HTTPD_VERSION) -O module/httpd.tar.gz

module/image.tar.gz:
	mkdir -p module/
	wget -nv https://gitorious.org/monsti/monsti-image/archive-tarball/$(IMAGE_VERSION) -O module/image.tar.gz

module/mail.tar.gz:
	mkdir -p module/
	wget -nv https://gitorious.org/monsti/monsti-mail/archive-tarball/$(MAIL_VERSION) -O module/mail.tar.gz

module/document.tar.gz:
	mkdir -p module/
	wget -nv https://gitorious.org/monsti/monsti-document/archive-tarball/$(DOCUMENT_VERSION) -O module/document.tar.gz

module/contactform.tar.gz:
	mkdir -p module/
	wget -nv https://gitorious.org/monsti/monsti-contactform/archive-tarball/$(CONTACTFORM_VERSION) -O module/contactform.tar.gz

module/%: module/%.tar.gz
	cd module; tar xf $*.tar.gz && mv monsti-monsti-$* $*
	mkdir -p locale/
	mkdir -p module/$*/locale/
	cp -Rn module/$*/locale .
	mkdir -p templates/
	mkdir -p module/$*/templates/
	ln -sf ../module/$*/templates templates/$*

templates/master.html: templates/httpd/master.html
	for i in $(wildcard templates/httpd/*); \
	do \
		ln -sf httpd/`basename $${i}` templates/`basename $${i}`; \
	done; \

$(MODULE_SOURCES): go/src/pkg.monsti.org/monsti-%: module/%
	mkdir -p go/src/pkg.monsti.org
	ln -sf ../../../module/$* go/src/pkg.monsti.org/monsti-$*

# Build module executable
.PHONY: $(MODULE_PROGRAMS)
$(MODULE_PROGRAMS): go/bin/monsti-%: go/src/pkg.monsti.org/monsti-%
	$(GO_GET) pkg.monsti.org/monsti-$*

.PHONY: tests
tests: $(MODULES:%=test-module-%) monsti-daemon/test-worker util/test-template util/test-testing\
	util/test-l10n rpc/test-client

test-module-%:
	$(GO_TEST) pkg.monsti.org/monsti-$*

test-%:
	$(GO_TEST) pkg.monsti.org/$*

.PHONY: clean
clean: clean-templates
	rm go/* -Rf
	rm static/aloha/ -R
	rm module/ -Rf
	rm locale/ -Rf

clean-templates:
	# FIXME rm templates/ -Rf

dep-aloha-editor: static/aloha/
static/aloha/:
	wget -nv http://aloha-editor.org/builds/stable/alohaeditor-$(ALOHA_VERSION).zip
	unzip -q alohaeditor-$(ALOHA_VERSION).zip
	mkdir static/aloha
	mv alohaeditor-$(ALOHA_VERSION)/aloha/lib static/aloha
	mv alohaeditor-$(ALOHA_VERSION)/aloha/css static/aloha
	mv alohaeditor-$(ALOHA_VERSION)/aloha/img static/aloha
	mv alohaeditor-$(ALOHA_VERSION)/aloha/plugins static/aloha
	rm alohaeditor-$(ALOHA_VERSION) -R
	rm alohaeditor-$(ALOHA_VERSION).zip

dep-jquery: static/js/jquery.min.js
static/js/jquery.min.js:
	wget -nv http://code.jquery.com/jquery-1.8.2.min.js
	mv jquery-1.8.2.min.js static/js/jquery.min.js
