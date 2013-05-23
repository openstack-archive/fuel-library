COMMIT_SHA:=$(shell git rev-parse --verify HEAD)
FUEL_VERSION:=3.0

CENTOS_MAJOR:=6
CENTOS_MINOR:=4
CENTOS_RELEASE:=$(CENTOS_MAJOR).$(CENTOS_MINOR)
CENTOS_ARCH:=x86_64

UBUNTU_DISTR:=precise
UBUNTU_ARCH:=amd64
UBUNTU_COMP:=main

FUEL_DIR:=$(PWD)/../deployment/puppet
SOURCE_DIR:=$(PWD)
BUILD_DIR:=$(PWD)/build

LOCAL_MIRROR:=$(PWD)/../../local_mirror
LOCAL_MIRROR_CENTOS:=$(LOCAL_MIRROR)/centos
LOCAL_MIRROR_CENTOS_OS_BASEURL:=$(LOCAL_MIRROR_CENTOS)/$(CENTOS_RELEASE)/os/$(CENTOS_ARCH)
LOCAL_MIRROR_UBUNTU:=$(LOCAL_MIRROR)/ubuntu/dists/$(UBUNTU_DISTR)
LOCAL_MIRROR_UBUNTU_DEB:=$(LOCAL_MIRROR_UBUNTU)/$(UBUNTU_COMP)/binary-$(UBUNTU_ARCH)
LOCAL_MIRROR_UBUNTU_INSTALLER:=$(LOCAL_MIRROR_UBUNTU)/$(UBUNTU_COMP)/debian-installer/binary-$(UBUNTU_ARCH)
MIRROR_CENTOS:=http://mirror.centos.org/centos
MIRROR_CENTOS_OS_BASEURL:=$(MIRROR_CENTOS)/$(CENTOS_RELEASE)/os/$(CENTOS_ARCH)
MIRROR_UBUNTU:=http://mirror.yandex.ru/ubuntu
MIRROR_UBUNTU_OS_BASEURL:=$(MIRROR_UBUNTU)/dists/$(UBUNTU_DISTR)/$(UBUNTU_COMP)
YUM_REPOS:=centos epel fuel_folsom puppetlabs rpmforge

include $(SOURCE_DIR)/mirror/module.mk

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(LOCAL_MIRROR)/ubuntu/dists
	rm -rf $(LOCAL_MIRROR)/ubuntu/etc
	rm -rf $(LOCAL_MIRROR)/ubuntu/var

deep_clean: clean
	rm -rf $(LOCAL_MIRROR)

.PHONY: iso clean
all: iso

ISOROOT:=$(BUILD_DIR)/iso/isoroot

#ifeq (foo, foo$(BUILD_ID))
#    BUILD_ID:=$(shell date +"%Y-%m-%d_%H-%M-%S")
#endif

ISOBASENAME:=fuel-centos-$(CENTOS_RELEASE)-$(CENTOS_ARCH)-$(FUEL_VERSION)
#[ -z "$$ISOSUFFIX" ] || ISOBASENAME:=$(ISOBASENAME)-$(ISOSUFFIX)
#ISOBASENAME:=fuel-centos-$(CENTOS_RELEASE)-$(CENTOS_ARCH)_$(BUILD_ID)

ISONAME:=$(BUILD_DIR)/iso/$(ISOBASENAME).iso

iso: $(ISONAME)

$(BUILD_DIR)/iso/isoroot-os.done: \
		$(BUILD_DIR)/mirror/build.done \
		$(BUILD_DIR)/iso/isoroot-dotfiles.done
	mkdir -p $(ISOROOT)/ubuntu
	rsync -rp $(LOCAL_MIRROR_CENTOS_OS_BASEURL)/ $(ISOROOT)
	rsync -rp $(LOCAL_MIRROR)/ubuntu/netboot $(ISOROOT)/ubuntu
	$(ACTION.TOUCH)

$(BUILD_DIR)/iso/isoroot-dotfiles.done: \
		$(ISOROOT)/.discinfo \
		$(ISOROOT)/.treeinfo
	$(ACTION.TOUCH)

$(BUILD_DIR)/iso/isoroot-files.done: \
		$(BUILD_DIR)/iso/isoroot-dotfiles.done \
		$(ISOROOT)/isolinux/isolinux.cfg \
		$(ISOROOT)/ks.cfg \
		$(ISOROOT)/bootstrap_admin_node.sh \
		$(ISOROOT)/functions.sh \
		$(ISOROOT)/bootstrap_admin_node.conf \
		$(ISOROOT)/version.yaml \
		$(ISOROOT)/fuel-modules.tgz \
		$(ISOROOT)/astute-0.0.1.gem
	$(ACTION.TOUCH)

$(ISOROOT)/fuel-modules.tgz: \
		$(call find-files,$(FUEL_DIR))
	(cd $(FUEL_DIR) && tar chzf $@ *)

$(ISOROOT)/astute-0.0.1.gem:
	mkdir -p $(@D)
	( cd $(SOURCE_DIR)/../deployment/mcollective/astute && gem build astute.gemspec )
	mv $(SOURCE_DIR)/../deployment/mcollective/astute/$(@F) $@

$(ISOROOT)/.discinfo: $(SOURCE_DIR)/.discinfo ; $(ACTION.COPY)
$(ISOROOT)/.treeinfo: $(SOURCE_DIR)/.treeinfo ; $(ACTION.COPY)
$(ISOROOT)/isolinux/isolinux.cfg: $(SOURCE_DIR)/isolinux/isolinux.cfg ; $(ACTION.COPY)
$(ISOROOT)/ks.cfg: $(SOURCE_DIR)/ks.cfg; $(ACTION.COPY)
	[ -z "$$TGTDRIVE" ] || sed -i "s/^\(tgtdrive=\)\".*\"$$/\1\"$$TGTDRIVE\"/" $@
	[ -z "$$USEEXTIF" ] || sed -i "s/^\(network\s*--bootproto=dhcp\.*\)/\1 --device=$$USEEXTIF/" $@
	[ -z "$$ISO_URL" ] || sed -i "s|^#\?url --url.*|url --url $$ISO_URL|" $@
	[ -z "$$BASE_MIRROR" ] || sed -i "s|^#\?repo --name=Base.*|repo --name=Base --mirrorlist=$$BASE_MIRROR|" $@
	[ -z "$$UPDATES_MIRROR" ] || sed -i "s|^#\?repo --name=Updates.*|repo --name=Updates --mirrorlist=$$UPDATES_MIRROR|" $@
	[ -z "$$MIRANTIS_MIRROR" ] || sed -i "s|^#\?repo --name=Mirantis.*|repo --name=Mirantis --mirrorlist=$$MIRANTIS_MIRROR|" $@
	[ -z "$$PUPPETLABS_MIRROR" ] || sed -i "s|^#\?repo --name=PuppetLabs.*|repo --name=PuppetLabs --mirrorlist=$$PUPPETLABS_MIRROR|" $@
$(ISOROOT)/bootstrap_admin_node.sh: $(SOURCE_DIR)/bootstrap_admin_node.sh ; $(ACTION.COPY)
$(ISOROOT)/functions.sh: $(SOURCE_DIR)/functions.sh ; $(ACTION.COPY)
$(ISOROOT)/bootstrap_admin_node.conf: $(SOURCE_DIR)/bootstrap_admin_node.conf ; $(ACTION.COPY)
$(ISOROOT)/version.yaml: $(call depv,COMMIT_SHA)
$(ISOROOT)/version.yaml: $(call depv,FUEL_VERSION)
$(ISOROOT)/version.yaml:
	echo "COMMIT_SHA: $(COMMIT_SHA)" > $@
	echo "PRODUCT_VERSION: $(FUEL_VERSION)" >> $@

########################
# Iso image root file system.
########################

$(BUILD_DIR)/iso/isoroot.done: \
		$(BUILD_DIR)/mirror/build.done \
		$(BUILD_DIR)/iso/isoroot-os.done \
		$(BUILD_DIR)/iso/isoroot-files.done
	$(ACTION.TOUCH)


########################
# Building CD image
########################

# keep in mind that mkisofs touches some files inside directory
# from which it builds iso image
# that is why we need to make $/isoroot.done dependent on some files
# and then copy these files into another directory

$(ISONAME): $(BUILD_DIR)/iso/isoroot.done
	rm -f $@
	mkdir -p $(BUILD_DIR)/iso/isoroot-mkisofs
	rsync -a --delete $(ISOROOT)/ $(BUILD_DIR)/iso/isoroot-mkisofs
	mkisofs -r -V "Mirantis Fuel $(FUEL_VERSION)" -p "Mirantis Inc." \
		-J -T -R -b isolinux/isolinux.bin \
		-no-emul-boot \
		-boot-load-size 4 -boot-info-table \
		-x "lost+found" -o $@ $(BUILD_DIR)/iso/isoroot-mkisofs
	implantisomd5 $@


####################### FUNCTIONS #############################

define ACTION.COPY
@mkdir -p $(@D)
cp $< $@
endef

define ACTION.TOUCH
@mkdir -p $(@D)
touch $@
endef

define depv
$(shell mkdir -p $(DEPV_DIR))
$(shell echo "$($1)" > $(DEPV_DIR)/$1.tmp)
$(shell diff >/dev/null 2>&1 $(DEPV_DIR)/$1.tmp $(DEPV_DIR)/$1.dep \
	|| mv $(DEPV_DIR)/$1.tmp $(DEPV_DIR)/$1.dep)
$(DEPV_DIR)/$1.dep
endef

$(BUILD_DIR)/%/.dir:
	mkdir -p $(@D)
	@touch $@

find-files=$(shell test -d $1 && find $1 -type f 2> /dev/null)
