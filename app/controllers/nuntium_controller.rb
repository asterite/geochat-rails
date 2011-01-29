class NuntiumController < ApplicationController
  def receive_at
    pipeline = Pipeline.new
    pipeline.process params.reject{|k, v| k == 'action' || k == 'controller'}

    nuntium = Nuntium.new NuntiumConfig['url'], NuntiumConfig['account'], NuntiumConfig['application'], NuntiumConfig['password']

    pipeline.messages.each do |target, messages|
      messages.each do |message|
        nuntium.send_ao :from => 'geochat://system', :to => target, :body => message
      end
    end
    head :ok
  end
end
