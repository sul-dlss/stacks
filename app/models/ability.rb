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

    can :download, [StacksFile, StacksImage] do |f|
      f.world_unrestricted?
    end

    can :download, [StacksFile, StacksImage] do |f|
      val, rule = f.world_rights
      val && rule.blank?
    end

    can :download, [StacksFile, StacksImage] do |f|
      val, rule = f.stanford_only_rights

      (val && rule.blank?) && user.webauth_user?
    end

    can :download, [StacksFile, StacksImage] do |f|
      val, rule = f.agent_rights(user.id)

      val && rule.blank? && user.app_user?
    end

    can :read, [StacksFile, StacksImage] do |f|
      can? :download, f
    end

    can :read, StacksImage do |f|
      f.thumbnail?
    end

    can :read, StacksImage do |f|
      f.tile? && can?(:access, f)
    end

    can :access, StacksImage do |f|
      val, rule = f.world_rights
      next true if val

      val, rule = f.stanford_only_rights
      next true if val && user.webauth_user?

      val, rule = f.agent_rights(user.id)
      next true if val && user.app_user?
    end

  end
end
