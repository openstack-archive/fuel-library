require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../lib/puppet/provider/pacemaker.rb'))

class PacemakerTest
  include Pacemaker

  def pcs(*value)
    puts value.inspect
  end
end

describe PacemakerTest do

  let(:raw_cib) do
<<-eos
<cib epoch="131" num_updates="3" admin_epoch="0" validate-with="pacemaker-1.2" cib-last-written="Fri Sep 12 18:20:44 2014" update-origin="node-1" update-client="crmd" crm_feature_set="3.0.7" have-quorum="0" dc-uuid="node-1">
  <configuration>
    <crm_config>
      <cluster_property_set id="cib-bootstrap-options">
        <nvpair id="cib-bootstrap-options-dc-version" name="dc-version" value="1.1.10-42f2063"/>
        <nvpair id="cib-bootstrap-options-cluster-infrastructure" name="cluster-infrastructure" value="classic openais (with plugin)"/>
        <nvpair id="cib-bootstrap-options-expected-quorum-votes" name="expected-quorum-votes" value="2"/>
        <nvpair id="cib-bootstrap-options-no-quorum-policy" name="no-quorum-policy" value="ignore"/>
        <nvpair id="cib-bootstrap-options-stonith-enabled" name="stonith-enabled" value="false"/>
        <nvpair id="cib-bootstrap-options-start-failure-is-fatal" name="start-failure-is-fatal" value="false"/>
        <nvpair id="cib-bootstrap-options-last-lrm-refresh" name="last-lrm-refresh" value="1410546044"/>
        <nvpair id="cib-bootstrap-options-mysqlprimaryinit" name="mysqlprimaryinit" value="done"/>
      </cluster_property_set>
    </crm_config>
    <nodes>
      <node id="node-1" uname="node-1"/>
    </nodes>
    <resources>
      <primitive class="ocf" id="vip__management_old" provider="mirantis" type="ns_IPaddr2">
        <operations>
          <op id="vip__management_old-monitor-2" interval="2" name="monitor" timeout="30"/>
          <op id="vip__management_old-start-0" interval="0" name="start" timeout="30"/>
          <op id="vip__management_old-stop-0" interval="0" name="stop" timeout="30"/>
        </operations>
        <instance_attributes id="vip__management_old-instance_attributes">
          <nvpair id="vip__management_old-instance_attributes-nic" name="nic" value="eth0.101"/>
          <nvpair id="vip__management_old-instance_attributes-ns_veth" name="ns_veth" value="hapr-m"/>
          <nvpair id="vip__management_old-instance_attributes-gateway" name="gateway" value="link"/>
          <nvpair id="vip__management_old-instance_attributes-gateway_metric" name="gateway_metric" value="20"/>
          <nvpair id="vip__management_old-instance_attributes-iptables_comment" name="iptables_comment" value="masquerade-for-management-net"/>
          <nvpair id="vip__management_old-instance_attributes-base_veth" name="base_veth" value="eth0.101-hapr"/>
          <nvpair id="vip__management_old-instance_attributes-ns" name="ns" value="haproxy"/>
          <nvpair id="vip__management_old-instance_attributes-cidr_netmask" name="cidr_netmask" value="24"/>
          <nvpair id="vip__management_old-instance_attributes-ip" name="ip" value="192.168.0.1"/>
          <nvpair id="vip__management_old-instance_attributes-iptables_start_rules" name="iptables_start_rules" value="iptables -t mangle -I PREROUTING -i eth0.101-hapr -j MARK --set-mark 0x2b ; iptables -t nat -I POSTROUTING -m mark --mark 0x2b ! -o eth0.101 -j MASQUERADE"/>
          <nvpair id="vip__management_old-instance_attributes-iptables_stop_rules" name="iptables_stop_rules" value="iptables -t mangle -D PREROUTING -i eth0.101-hapr -j MARK --set-mark 0x2b ; iptables -t nat -D POSTROUTING -m mark --mark 0x2b ! -o eth0.101 -j MASQUERADE"/>
          <nvpair id="vip__management_old-instance_attributes-iflabel" name="iflabel" value="ka"/>
        </instance_attributes>
        <meta_attributes id="vip__management_old-meta_attributes">
          <nvpair id="vip__management_old-meta_attributes-resource-stickiness" name="resource-stickiness" value="1"/>
        </meta_attributes>
      </primitive>
      <primitive class="ocf" id="vip__public_old" provider="mirantis" type="ns_IPaddr2">
        <operations>
          <op id="vip__public_old-monitor-2" interval="2" name="monitor" timeout="30"/>
          <op id="vip__public_old-start-0" interval="0" name="start" timeout="30"/>
          <op id="vip__public_old-stop-0" interval="0" name="stop" timeout="30"/>
        </operations>
        <instance_attributes id="vip__public_old-instance_attributes">
          <nvpair id="vip__public_old-instance_attributes-nic" name="nic" value="eth1"/>
          <nvpair id="vip__public_old-instance_attributes-ns_veth" name="ns_veth" value="hapr-p"/>
          <nvpair id="vip__public_old-instance_attributes-gateway" name="gateway" value="link"/>
          <nvpair id="vip__public_old-instance_attributes-gateway_metric" name="gateway_metric" value="10"/>
          <nvpair id="vip__public_old-instance_attributes-iptables_comment" name="iptables_comment" value="masquerade-for-public-net"/>
          <nvpair id="vip__public_old-instance_attributes-base_veth" name="base_veth" value="eth1-hapr"/>
          <nvpair id="vip__public_old-instance_attributes-ns" name="ns" value="haproxy"/>
          <nvpair id="vip__public_old-instance_attributes-cidr_netmask" name="cidr_netmask" value="24"/>
          <nvpair id="vip__public_old-instance_attributes-ip" name="ip" value="172.16.0.2"/>
          <nvpair id="vip__public_old-instance_attributes-iptables_start_rules" name="iptables_start_rules" value="iptables -t mangle -I PREROUTING -i eth1-hapr -j MARK --set-mark 0x2a ; iptables -t nat -I POSTROUTING -m mark --mark 0x2a ! -o eth1 -j MASQUERADE"/>
          <nvpair id="vip__public_old-instance_attributes-iptables_stop_rules" name="iptables_stop_rules" value="iptables -t mangle -D PREROUTING -i eth1-hapr -j MARK --set-mark 0x2a ; iptables -t nat -D POSTROUTING -m mark --mark 0x2a ! -o eth1 -j MASQUERADE"/>
          <nvpair id="vip__public_old-instance_attributes-iflabel" name="iflabel" value="ka"/>
        </instance_attributes>
        <meta_attributes id="vip__public_old-meta_attributes">
          <nvpair id="vip__public_old-meta_attributes-resource-stickiness" name="resource-stickiness" value="1"/>
        </meta_attributes>
      </primitive>
      <clone id="clone_p_haproxy">
        <meta_attributes id="clone_p_haproxy-meta_attributes">
          <nvpair id="clone_p_haproxy-meta_attributes-interleave" name="interleave" value="true"/>
          <nvpair id="clone_p_haproxy-meta_attributes-is-managed" name="is-managed" value="true"/>
        </meta_attributes>
        <primitive class="ocf" id="p_haproxy" provider="mirantis" type="ns_haproxy">
          <operations>
            <op id="p_haproxy-monitor-20" interval="20" name="monitor" timeout="10"/>
            <op id="p_haproxy-start-0" interval="0" name="start" timeout="30"/>
            <op id="p_haproxy-stop-0" interval="0" name="stop" timeout="30"/>
          </operations>
          <instance_attributes id="p_haproxy-instance_attributes">
            <nvpair id="p_haproxy-instance_attributes-ns" name="ns" value="haproxy"/>
          </instance_attributes>
          <meta_attributes id="p_haproxy-meta_attributes">
            <nvpair id="p_haproxy-meta_attributes-migration-threshold" name="migration-threshold" value="3"/>
            <nvpair id="p_haproxy-meta_attributes-failure-timeout" name="failure-timeout" value="120"/>
          </meta_attributes>
        </primitive>
      </clone>
      <clone id="clone_p_mysql">
        <meta_attributes id="clone_p_mysql-meta_attributes">
          <nvpair id="clone_p_mysql-meta_attributes-interleave" name="interleave" value="true"/>
          <nvpair id="clone_p_mysql-meta_attributes-is-managed" name="is-managed" value="true"/>
        </meta_attributes>
        <primitive class="ocf" id="p_mysql" provider="mirantis" type="mysql-wss">
          <operations>
            <op id="p_mysql-monitor-60" interval="60" name="monitor" timeout="55"/>
            <op id="p_mysql-start-0" interval="0" name="start" timeout="475"/>
            <op id="p_mysql-stop-0" interval="0" name="stop" timeout="175"/>
          </operations>
        </primitive>
      </clone>
      <primitive class="ocf" id="heat-engine" provider="mirantis" type="heat-engine">
        <operations>
          <op id="heat-engine-monitor-20" interval="20" name="monitor" timeout="30"/>
          <op id="heat-engine-start-0" interval="0" name="start" timeout="60"/>
          <op id="heat-engine-stop-0" interval="0" name="stop" timeout="60"/>
        </operations>
        <meta_attributes id="heat-engine-meta_attributes">
          <nvpair id="heat-engine-meta_attributes-resource-stickiness" name="resource-stickiness" value="1"/>
          <nvpair id="heat-engine-meta_attributes-is-managed" name="is-managed" value="false"/>
          <nvpair id="heat-engine-meta_attributes-target-role" name="target-role" value="Stopped"/>
        </meta_attributes>
      </primitive>
    </resources>
    <constraints>
      <rsc_colocation id="vip_management-with-haproxy" rsc="vip__management_old" score="INFINITY" with-rsc="clone_p_haproxy"/>
      <rsc_colocation id="vip_public-with-haproxy" rsc="vip__public_old" score="INFINITY" with-rsc="clone_p_haproxy"/>
    </constraints>
  </configuration>
  <status>
    <node_state id="node-1" uname="node-1" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <transient_attributes id="node-1">
        <instance_attributes id="status-node-1">
          <nvpair id="status-node-1-probe_complete" name="probe_complete" value="true"/>
          <nvpair id="status-node-1-last-failure-heat-engine" name="last-failure-heat-engine" value="1410545131"/>
        </instance_attributes>
      </transient_attributes>
      <lrm id="node-1">
        <lrm_resources>
          <lrm_resource id="vip__management_old" type="ns_IPaddr2" class="ocf" provider="mirantis">
            <lrm_rsc_op id="vip__management_old_last_0" operation_key="vip__management_old_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.0.7" transition-key="5:4:0:e4da4495-5fc9-4390-beea-c65986c430d2" transition-magic="0:0;5:4:0:e4da4495-5fc9-4390-beea-c65986c430d2" call-id="8" rc-code="0" op-status="0" interval="0" last-run="1410541444" last-rc-change="1410541444" exec-time="1264" queue-time="0" op-digest="55c0a6e6ace3998b15503d18a335f63c"/>
            <lrm_rsc_op id="vip__management_old_monitor_2000" operation_key="vip__management_old_monitor_2000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.0.7" transition-key="6:4:0:e4da4495-5fc9-4390-beea-c65986c430d2" transition-magic="0:0;6:4:0:e4da4495-5fc9-4390-beea-c65986c430d2" call-id="11" rc-code="0" op-status="0" interval="2000" last-rc-change="1410541445" exec-time="2086" queue-time="0" op-digest="0e9fe9648d582ed30bbb4475affd853d"/>
          </lrm_resource>
          <lrm_resource id="vip__public_old" type="ns_IPaddr2" class="ocf" provider="mirantis">
            <lrm_rsc_op id="vip__public_old_last_0" operation_key="vip__public_old_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.0.7" transition-key="8:5:0:e4da4495-5fc9-4390-beea-c65986c430d2" transition-magic="0:0;8:5:0:e4da4495-5fc9-4390-beea-c65986c430d2" call-id="19" rc-code="0" op-status="0" interval="0" last-run="1410541454" last-rc-change="1410541454" exec-time="1216" queue-time="0" op-digest="7efb5f02fc8fa26172c79792fb85f362"/>
            <lrm_rsc_op id="vip__public_old_monitor_2000" operation_key="vip__public_old_monitor_2000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.0.7" transition-key="9:5:0:e4da4495-5fc9-4390-beea-c65986c430d2" transition-magic="0:0;9:5:0:e4da4495-5fc9-4390-beea-c65986c430d2" call-id="22" rc-code="0" op-status="0" interval="2000" last-rc-change="1410541456" exec-time="2114" queue-time="0" op-digest="3d6425d3c79376991ec762893392ac1b"/>
          </lrm_resource>
          <lrm_resource id="p_haproxy" type="ns_haproxy" class="ocf" provider="mirantis">
            <lrm_rsc_op id="p_haproxy_last_failure_0" operation_key="p_haproxy_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.0.7" transition-key="8:191:7:e4da4495-5fc9-4390-beea-c65986c430d2" transition-magic="0:0;8:191:7:e4da4495-5fc9-4390-beea-c65986c430d2" call-id="705" rc-code="0" op-status="0" interval="0" last-run="1410545830" last-rc-change="1410545830" exec-time="86" queue-time="0" op-digest="2a23892614b6b1d0f70ca66b073b5bc0"/>
            <lrm_rsc_op id="p_haproxy_monitor_20000" operation_key="p_haproxy_monitor_20000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.0.7" transition-key="14:192:0:e4da4495-5fc9-4390-beea-c65986c430d2" transition-magic="0:0;14:192:0:e4da4495-5fc9-4390-beea-c65986c430d2" call-id="708" rc-code="1" op-status="0" interval="20000" last-rc-change="1410545831" exec-time="68" queue-time="0" op-digest="3513c6578b2be63b3c075d885eb6ac8d"/>
          </lrm_resource>
          <lrm_resource id="p_mysql" type="mysql-wss" class="ocf" provider="mirantis">
            <lrm_rsc_op id="p_mysql_last_failure_0" operation_key="p_mysql_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.0.7" transition-key="8:195:7:e4da4495-5fc9-4390-beea-c65986c430d2" transition-magic="0:0;8:195:7:e4da4495-5fc9-4390-beea-c65986c430d2" call-id="717" rc-code="0" op-status="0" interval="0" last-run="1410545862" last-rc-change="1410545862" exec-time="33" queue-time="0" op-digest="f2317cad3d54cec5d7d7aa7d0bf35cf8"/>
            <lrm_rsc_op id="p_mysql_monitor_60000" operation_key="p_mysql_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.0.7" transition-key="20:196:0:e4da4495-5fc9-4390-beea-c65986c430d2" transition-magic="0:0;20:196:0:e4da4495-5fc9-4390-beea-c65986c430d2" call-id="720" rc-code="0" op-status="0" interval="60000" last-rc-change="1410545862" exec-time="34" queue-time="0" op-digest="2494f1d4e3d3f4d66d4ec4e1d38a7f68"/>
          </lrm_resource>
          <lrm_resource id="heat-engine" type="heat-engine" class="ocf" provider="mirantis">
            <lrm_rsc_op id="heat-engine_last_failure_0" operation_key="heat-engine_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.0.7" transition-key="8:211:7:e4da4495-5fc9-4390-beea-c65986c430d2" transition-magic="0:0;8:211:7:e4da4495-5fc9-4390-beea-c65986c430d2" call-id="786" rc-code="0" op-status="0" interval="0" last-run="1410546044" last-rc-change="1410546044" exec-time="11" queue-time="0" op-digest="f2317cad3d54cec5d7d7aa7d0bf35cf8"/>
            <lrm_rsc_op id="heat-engine_monitor_20000" operation_key="heat-engine_monitor_20000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.0.7" transition-key="26:212:0:e4da4495-5fc9-4390-beea-c65986c430d2" transition-magic="0:0;26:212:0:e4da4495-5fc9-4390-beea-c65986c430d2" call-id="789" rc-code="0" op-status="0" interval="20000" last-rc-change="1410546044" exec-time="13" queue-time="0" op-digest="02a5bcf940fc8d3239701acb11438d6a"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
    </node_state>
  </status>
</cib>
eos
  end

  let(:resources_regexp) do
    %r{nova|cinder|glance|keystone|neutron|sahara|murano|ceilometer|heat|swift}
  end

  ###########################

  before(:each) do
    @class = subject
    @class.stubs(:raw_cib).returns raw_cib
    #@class.stubs(:pcs).returns true
  end

  context 'configuration parser' do
    it 'can obtain a CIB XML object' do
      expect(@class.cib.to_s).to include '<configuration>'
      expect(@class.cib.to_s).to include '<nodes>'
      expect(@class.cib.to_s).to include '<resources>'
      expect(@class.cib.to_s).to include '<status>'
      expect(@class.cib.to_s).to include '<operations>'
    end

    it 'can get primitives section of CIB XML' do
      expect(@class.cib_section_primitives.to_s).to start_with '<primitive'
      expect(@class.cib_section_primitives.to_s).to end_with '</primitive>'
    end

    it 'can get primitives configuration' do
      expect(@class.primitives).to be_a Hash
      expect(@class.primitives['vip__public_old']).to be_a Hash
      expect(@class.primitives['vip__public_old']['meta_attributes']).to be_a Hash
      expect(@class.primitives['vip__public_old']['instance_attributes']).to be_a Hash
      expect(@class.primitives['vip__public_old']['instance_attributes']['ip']).to be_a Hash
      expect(@class.primitives['vip__public_old']['operations']).to be_a Hash
      expect(@class.primitives['vip__public_old']['meta_attributes']['resource-stickiness']).to be_a Hash
      expect(@class.primitives['vip__public_old']['operations']['vip__public_old-monitor-2']).to be_a Hash
    end

    it 'can determine is primitive is simple or complex' do
      expect(@class.primitive_is_complex? 'p_haproxy').to be_truthy
      expect(@class.primitive_is_complex? 'vip__management_old').to be_falsey
    end
  end

  context 'node status parser' do
    it 'can produce nodes structure' do
      expect(@class.nodes).to be_a Hash
      expect(@class.nodes['node-1']['primitives']['heat-engine']['status']).to eq('start')
    end

    it 'can determite a global primitive status' do
      expect(@class.primitive_status 'heat-engine').to eq('start')
      expect(@class.primitive_running? 'heat-engine').to be_truthy
      expect(@class.primitive_status 'p_haproxy').to eq('stop')
      expect(@class.primitive_running? 'p_haproxy').to be_falsey
    end

    it 'can determine a local primitive status on a node' do
      expect(@class.primitive_status 'heat-engine', 'node-1').to eq('start')
      expect(@class.primitive_running? 'heat-engine', 'node-1').to be_truthy
      expect(@class.primitive_status 'p_haproxy', 'node-1').to eq('stop')
      expect(@class.primitive_running? 'p_haproxy', 'node-1').to be_falsey
    end

    it 'can determine if primitive is managed or not' do
      expect(@class.primitive_is_managed? 'heat-engine').to be_falsey
      expect(@class.primitive_is_managed? 'p_haproxy').to be_truthy
    end

    it 'can determine if primitive is started or not' do
      expect(@class.primitive_is_started? 'heat-engine').to be_falsey
      expect(@class.primitive_is_started? 'p_haproxy').to be_truthy
    end

    it 'can determine if primitive is failed or not' do
      expect(@class.primitive_has_failures? 'p_haproxy').to be_truthy
      expect(@class.primitive_has_failures? 'heat-engine').to be_falsey
      expect(@class.primitive_has_failures? 'p_haproxy', 'node-1').to be_truthy
      expect(@class.primitive_has_failures? 'heat-engine', 'node-1').to be_falsey
    end
  end

  context 'cluster control' do
    it 'can enable maintenance mode' do
      @class.expects(:pcs).with 'property', 'set', 'maintenance-mode=true'
      @class.maintenance_mode 'true'
    end

    it 'can disable maintenance mode' do
      @class.expects(:pcs).with 'property', 'set', 'maintenance-mode=false'
      @class.maintenance_mode 'false'
    end

    it 'can set no-quorum policy' do
      @class.expects(:pcs).with 'property', 'set', 'no-quorum-policy=ignore'
      @class.no_quorum_policy 'ignore'
    end
  end

  context 'constraints control' do
    it 'can add location constraint' do
      @class.expects(:pcs).with 'constraint', 'location', 'add', 'myprimitive_on_mynode', 'myprimitive', 'mynode', '200'
      @class.constraint_location_add 'myprimitive', 'mynode', '200'
    end

    it 'can remove location constraint' do
      @class.expects(:pcs).with 'constraint', 'location', 'remove', 'myprimitive_on_mynode'
      @class.constraint_location_remove 'myprimitive', 'mynode'
    end
  end

  context 'wait functions' do
    it 'retries block until it becomes true' do
      @class.retry_block_until_true { true }
    end

    it 'waits for Pacemaker to become ready' do
      @class.stubs(:is_online?).returns true
      @class.wait_for_online
    end

    it 'cleanups primitive and waits for it to become online again' do
      @class.stubs(:cleanup_primitive).with('myprimitive').returns true
      @class.stubs(:cib_reset).returns true
      @class.stubs(:primitive_running?).returns true
      @class.cleanup_with_wait 'myprimitive'
    end

    it 'waits for the service to start' do
      @class.stubs(:cib_reset).returns true
      @class.stubs(:primitive_running?).with('myprimitive', nil).returns true
      @class.wait_for_start 'myprimitive'
    end

    it 'waits for the service to stop' do
      @class.stubs(:cib_reset).returns true
      @class.stubs(:primitive_running?).with('myprimitive', nil).returns false
      @class.wait_for_stop 'myprimitive'
    end
  end

end
