class Link < ArvadosModel
  include AssignUuid
  include KindAndEtag
  include CommonApiTemplate
  serialize :properties, Hash
  before_create :permission_to_attach_to_objects
  before_update :permission_to_attach_to_objects
  after_update :maybe_invalidate_permissions_cache
  after_create :maybe_invalidate_permissions_cache
  after_destroy :maybe_invalidate_permissions_cache

  attr_accessor :head
  attr_accessor :tail

  api_accessible :user, extend: :common do |t|
    t.add :tail_kind
    t.add :tail_uuid
    t.add :link_class
    t.add :name
    t.add :head_kind
    t.add :head_uuid
    t.add :head, :if => :head
    t.add :tail, :if => :tail
    t.add :properties
  end

  def properties
    @properties ||= Hash.new
    super
  end

  protected

  def permission_to_attach_to_objects
    # Anonymous users cannot write links
    return false if !current_user

    # All users can write links that don't affect permissions
    return true if self.link_class != 'permission'

    # Administrators can grant permissions
    return true if current_user.is_admin

    # All users can grant permissions on objects they own
    head_obj = self.class.
      kind_class(self.head_kind).
      where('uuid=?',head_uuid).
      first
    if head_obj
      return true if head_obj.owner_uuid == current_user.uuid
    end

    # Users with "can_grant" permission on an object can grant
    # permissions on that object
    has_grant_permission = self.class.
      where('link_class=? AND name=? AND tail_uuid=? AND head_uuid=?',
            'permission', 'can_grant', current_user.uuid, self.head_uuid).
      count > 0
    return true if has_grant_permission

    # Default = deny.
    false
  end

  def maybe_invalidate_permissions_cache
    if self.link_class == 'permission'
      # Clearing the entire permissions cache can generate many
      # unnecessary queries if many active users are not affected by
      # this change. In such cases it would be better to search cached
      # permissions for head_uuid and tail_uuid, and invalidate the
      # cache for only those users. (This would require a browseable
      # cache.)
      User.invalidate_permissions_cache
    end
  end
end
