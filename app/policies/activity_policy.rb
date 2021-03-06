class ActivityPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.treasurer?
        scope
      elsif user&.main_bartender?
        scope.not_locked
      end
    end
  end

  def create?
    user&.treasurer? || user&.main_bartender?
  end

  def update?
    user&.treasurer? || user&.main_bartender?
  end

  def lock?
    user&.treasurer? && !record.locked?
  end

  def create_invoices?
    user&.treasurer? && record.locked?
  end

  def destroy?
    user&.treasurer? || user&.main_bartender?
  end

  def activity_report?
    user&.treasurer?
  end

  def order_screen?
    user&.treasurer? || user&.main_bartender?
  end

  def product_totals?
    user&.treasurer? || user&.main_bartender?
  end
end
