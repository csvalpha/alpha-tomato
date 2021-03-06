module SlackHelper
  delegate :ping, to: :notifier

  private

  def notifier
    @notifier ||= Slack::Notifier.new(
      Rails.application.config.x.slack_webhook,
      username: 'SOFIA',
      channel: Rails.application.config.x.slack_channel
    )
  end
end
