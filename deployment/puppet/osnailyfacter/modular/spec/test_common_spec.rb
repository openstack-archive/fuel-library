require 'spec_helper'
require File.join File.dirname(__FILE__), '../test_common.rb'

describe TestCommon do
  context TestCommon::Settings do
    before :each do
      allow(subject.hiera).to receive(:lookup).with('id', nil, {}).and_return('1')
    end

    it 'can get the hiera object' do
      expect(subject.hiera).to be_a Hiera
    end

    it 'can lookup a settings value' do
      expect(subject.lookup 'id').to eq('1')
    end

    it 'can lookup by index or method' do
      expect(subject.id).to eq('1')
      expect(subject['id']).to eq('1')
    end
  end

  context TestCommon::HAProxy do
    let :csv do
      <<-eof
# pxname,svname,qcur,qmax,scur,smax,slim,stot,bin,bout,dreq,dresp,ereq,econ,eresp,wretr,wredis,status,weight,act,bck,chkfail,chkdown,lastchg,downtime,qlimit,pid,iid,sid,throttle,lbtot,tracked,type,rate,rate_lim,rate_max,check_status,check_code,check_duration,hrsp_1xx,hrsp_2xx,hrsp_3xx,hrsp_4xx,hrsp_5xx,hrsp_other,hanafail,req_rate,req_rate_max,req_tot,cli_abrt,srv_abrt,comp_in,comp_out,comp_byp,comp_rsp,lastsess,last_chk,last_agt,qtime,ctime,rtime,ttime,
Stats,FRONTEND,,,0,2,8000,479,3959708,1147775737,0,0,0,,,,,OPEN,,,,,,,,,1,2,0,,,,0,0,0,6,,,,0,11394,0,0,0,0,,0,8,11394,,,0,0,0,0,,,,,,,,
Stats,BACKEND,0,0,0,0,800,0,3959708,1147775737,0,0,,0,0,0,0,UP,0,0,0,,0,347258,0,,1,2,0,,0,,1,0,,0,,,,0,0,0,0,0,0,,,,,0,0,0,0,0,0,319035,,,0,0,0,2585,
horizon,FRONTEND,,,0,0,8000,0,0,0,0,0,0,,,,,OPEN,,,,,,,,,1,3,0,,,,0,0,0,0,,,,0,0,0,0,0,0,,0,0,0,,,0,0,0,0,,,,,,,,
horizon,node-7,0,0,0,0,,0,0,0,,0,,0,0,0,0,DOWN,1,1,0,3,1,10,10,,1,3,1,,0,,2,0,,0,L4CON,,0,0,0,0,0,0,0,0,,,,0,0,,,,,-1,Connection refused,,0,0,0,0,
horizon,BACKEND,0,0,0,0,800,0,0,0,0,0,,0,0,0,0,DOWN,0,0,0,,1,10,10,,1,3,0,,0,,1,0,,0,,,,0,0,0,0,0,0,,,,,0,0,0,0,0,0,-1,,,0,0,0,0,
keystone-1,FRONTEND,,,0,1,8000,25,4200,22925,0,0,0,,,,,OPEN,,,,,,,,,1,4,0,,,,0,0,0,1,,,,0,0,25,0,0,0,,0,1,25,,,0,0,0,0,,,,,,,,
keystone-1,node-7,0,0,0,1,,25,4200,22925,,0,,0,0,0,0,UP,1,1,0,0,0,347258,0,,1,4,1,,25,,2,0,,1,L7OK,300,2,0,0,25,0,0,0,0,,,,0,0,,,,,332047,Multiple Choices,,0,0,1,1,
keystone-1,BACKEND,0,0,0,1,800,25,4200,22925,0,0,,0,0,0,0,UP,1,1,0,,0,347258,0,,1,4,0,,25,,1,0,,1,,,,0,0,25,0,0,0,,,,,0,0,0,0,0,0,332047,,,0,0,1,1,
keystone-2,FRONTEND,,,0,2,8000,135,31659,695738,0,0,0,,,,,OPEN,,,,,,,,,1,5,0,,,,0,0,0,4,,,,0,105,30,0,0,0,,0,4,135,,,0,0,0,0,,,,,,,,
keystone-2,node-7,0,0,0,1,,135,31659,695738,,0,,0,0,0,0,UP,1,1,0,0,0,347258,0,,1,5,1,,135,,2,0,,4,L7OK,300,3,0,105,30,0,0,0,0,,,,0,0,,,,,331832,Multiple Choices,,0,1,16,17,
keystone-2,BACKEND,0,0,0,1,800,135,31659,695738,0,0,,0,0,0,0,UP,1,1,0,,0,347258,0,,1,5,0,,135,,1,0,,4,,,,0,105,30,0,0,0,,,,,0,0,0,0,0,0,331832,,,0,1,16,17,
      eof
    end

    let :backends do
      {"Stats"=>"UP", "horizon"=>"DOWN", "keystone-1"=>"UP", "keystone-2"=>"UP"}
    end

    before :each do
      allow(TestCommon::Settings.hiera).to receive(:lookup).with('management_vip', nil, {}).and_return('127.0.0.1')
      allow(TestCommon::Settings.hiera).to receive(:lookup).with('controller_node_address', nil, {}).and_return('127.0.0.1')
      allow(subject).to receive(:csv).and_return(csv)
    end

    it 'can get the HAProxy stats url' do
      expect(subject.stats_url).to eq('http://127.0.0.1:10000/;csv')
    end

    it 'can parse stats csv' do
      expect(subject.backends).to eq(backends)
    end

    it 'can chack if a backend exists' do
      expect(subject.backend_present? 'horizon').to eq true
      expect(subject.backend_present? 'MISSING').to eq false
    end

    it 'can chack if a backend is up' do
      expect(subject.backend_up? 'horizon').to eq false
      expect(subject.backend_up? 'keystone-1').to eq true
      expect(subject.backend_up? 'MISSING').to eq false
    end

  end
end
