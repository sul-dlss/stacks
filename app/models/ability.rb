##
# User authentication
# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    # Note:  rule.blank?  means it's allowed (e.g. 'no-download' would be a value)

    can :download, [StacksFile, StacksImage, StacksMediaStream], &:world_unrestricted?

    can :download, [StacksFile, StacksImage, StacksMediaStream] do |f|
      val, rule = f.world_rights

      val && rule.blank?
    end

    # location based rights exclude when NOT matching the location condition
    #   (all other rights include when matching conditions)
    cannot :download, [StacksFile, StacksImage, StacksMediaStream] do |f|
      user_in_location, rule = f.location_rights(user.location)

      # location OR stanford, not location AND stanford
      f.restricted_by_location? && (!user_in_location || !rule.blank?)
    end

    # media download rights exclude when rule is no-download
    # stanford restricted, read, but no download
    cannot :download, StacksMediaStream do |f|
      stanford_only_rights, rule = f.stanford_only_rights
      stanford_only_rights && rule == 'no-download'
    end

    # media download rights exclude when rule is no-download
    # world restricted, read, but no download
    cannot :download, StacksMediaStream do |f|
      world_rights_defined, rule = f.world_rights
      world_rights_defined && rule == 'no-download'
    end

    can :download, [StacksFile, StacksImage, StacksMediaStream] do |f|
      val, rule = f.stanford_only_rights

      (val && rule.blank?) && user.stanford?
    end

    can :download, [StacksFile, StacksImage, StacksMediaStream] do |f|
      val, rule = f.agent_rights(user.id)

      val && rule.blank? && user.app_user?
    end

    can :download, [StacksFile, StacksImage, StacksMediaStream] do |f|
      val, rule = f.location_rights(user.location)

      val && rule.blank? && f.restricted_by_location?
    end

    can :read, [StacksFile, StacksImage, StacksMediaStream] do |f|
      can? :download, f
    end

    can :read, StacksMediaStream do |f|
      user_in_location, _rule = f.location_rights(user.location)
      f.restricted_by_location? && user_in_location
    end

    can :read, StacksMediaStream do |f|
      stanford_only_rights, _rule = f.stanford_only_rights
      stanford_only_rights && user.stanford?
    end

    can :read, StacksMediaStream do |f|
      world_rights_defined, _rule = f.world_rights
      world_rights_defined
    end

    can :read, StacksImage, &:thumbnail?

    can :read, StacksImage do |f|
      f.tile? && can?(:access, f)
    end

    can :read_metadata, StacksImage

    can :access, StacksImage do |f|
      val, _rule = f.world_rights
      next true if val

      val, _rule = f.stanford_only_rights
      next true if val && user.stanford?

      val, _rule = f.agent_rights(user.id)
      next true if val && user.app_user?
    end
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
