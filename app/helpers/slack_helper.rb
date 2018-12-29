module SlackHelper
  delegate :ping, to: :notifier

  private

  def notifier
    @notifier ||= Slack::Notifier.new(
      Rails.application.config.x.slack_wehbook,
      username: 'Sofia',
      channel: Rails.application.config.x.slack_channel
    )
  end
end
