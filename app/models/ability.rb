##
# User authentication
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

    can :download, [StacksFile, StacksImage, StacksMediaStream], &:world_downloadable?
    can :download, [StacksFile, StacksImage, StacksMediaStream] do |f|
      f.stanford_only_downloadable? && user.stanford?
    end
    can :download, [StacksFile, StacksImage, StacksMediaStream] do |f|
      f.agent_downloadable?(user.id)
    end
    can :download, [StacksFile, StacksImage, StacksMediaStream] do |f|
      f.location_downloadable?(user.location)
    end

    can :read, [StacksFile, StacksImage, StacksMediaStream] do |f|
      can? :download, f
    end

    # Alias 'stream' to 'read' for StacksMediaStream so
    # we can set streaming specific authorization rules
    can :stream, StacksMediaStream do |f|
      can? :read, f
    end

    # To enable streaming of non-downloadable content we can
    # override the World, Location, and Stanford rights for
    # streaming regarldess of the rule applied in rights
    if Settings.features.location_auth
      can :stream, StacksMediaStream do |f|
        user_in_location, _rule = f.location_rights(user.location)
        f.restricted_by_location? && user_in_location
      end
    end

    can :stream, StacksMediaStream do |f|
      stanford_only_rights, _rule = f.stanford_only_rights
      stanford_only_rights && user.stanford?
    end

    can :stream, StacksMediaStream do |f|
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

      val, _rule = f.location_rights(user.location)
      next true if val
    end
  end
end
