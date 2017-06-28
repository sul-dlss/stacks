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
    # If you pass :all, it will apply to every resource. Otherwise, pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects. For example, here the user can only update published articles.
    #   can :update, Article, :published => true
    #
    # The block argument takes as a parameter an instance of the object for which
    # permission is being checked. If the block returns true, the user is granted that
    # ability, otherwise the user is denied that ability. The block is only evaluated
    # for instances of objects, *not* for classes. If a class is passed to a `can?` or a
    # `cannot?` that's defined by a block, that check will *always* grant permission.
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities-with-Blocks

    # NOTE: the below ability definitions which reference StacksFile also implicitly
    # cover StacksImage and StacksMediaStream, and any other subclasses of StacksFile.

    can :download, StacksFile, &:world_downloadable?
    can :download, StacksFile do |f|
      f.stanford_only_downloadable? && user.stanford?
    end
    can :download, StacksFile do |f|
      f.agent_downloadable?(user.id) && user.app_user?
    end
    can :download, StacksFile do |f|
      f.location_downloadable?(user.location)
    end

    can :read, StacksFile do |f|
      can? :download, f
    end
    can :read, StacksImage, &:thumbnail?
    can :read, StacksImage do |f|
      f.tile? && can?(:access, f)
    end

    can :stream, StacksMediaStream do |f|
      can? :access, f
    end

    can :read_metadata, StacksImage

    can :access, StacksFile do |f|
      world_rights_defined, _rule = f.world_rights
      next true if world_rights_defined

      stanford_only_rights_defined, _rule = f.stanford_only_rights
      next true if stanford_only_rights_defined && user.stanford?

      agent_rights_defined, _rule = f.agent_rights(user.id)
      next true if agent_rights_defined && user.app_user?

      location_rights_defined, _rule = f.location_rights(user.location)
      next true if location_rights_defined
    end
  end
end
