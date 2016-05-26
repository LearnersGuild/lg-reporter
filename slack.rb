require 'json'

module Slack
  class Response
    attr_accessor :text, :type, :attachments

    def initialize(text, type='ephemeral')
      @text = text
      @type = type # options: ['in_channel', 'ephemeral']
    end

    def data
      response_data = {
        text: text,
        response_type: type,
        mrkdwn: true
      }

      if attachments.any?
        attachments.each { |a| a['mrkdwn_in'] = ['text', 'pretext'] }
        response_data[:attachments] = attachments
      end

      response_data
    end
  end
end
