class DocLoader
  def initialize(options, store)
    @options = options
    @store = store
  end

  def load
    build_classes
  end

  private

  def build_classes
    classes = @store.all_classes_and_modules

    classes = classes.select do |klass|
      !skip_class? klass.full_name
    end

    classes.sort_by!(&:full_name)

    ret = classes.map do |klass|
      {
        id:      klass.full_name,
        title:   klass.full_name,
        kind:    get_class_kind(klass.full_name),
        comment: get_comment(klass),
        groups:  build_groups(klass)
      }
    end

    with_indicators ret
  end

  def build_groups(klass)
    members = build_members(klass)
    groups = {}

    members.each do |member|
      group = get_member_group(member)
      next unless group

      group_id = klass.full_name.strip + '::' + group[:title].strip

      unless groups.include? group_id
        groups[group_id] = group.merge(
          id: group_id,
          members: []
        )
      end

      groups[group_id][:members] << member
    end

    groups.values
  end

  def build_members(klass)
    members = []

    method_members = build_members_from_list klass.method_list do |member|
      member[:kind] = :method
    end

    attr_members = build_members_from_list klass.attributes do |member|
      member[:kind] = :attribute
    end

    const_members = build_members_from_list klass.constants do |member|
      member[:kind] = :constant
    end

    extends_members = build_members_from_list klass.extends do |member|
      member[:kind] = :extended
    end

    include_members = build_members_from_list klass.includes do |member|
      member[:kind] = :included
    end

    members.push(*method_members)
    members.push(*attr_members)
    members.push(*const_members)
    members.push(*extends_members)
    members.push(*include_members)

    with_indicators members
  end

  def build_members_from_list(member_list)
    members = []

    member_list.each do |m|
      next if skip_member? m.name

      member = {}
      member[:id] = if m.respond_to? :arglists
                      if m.arglists
                        m.arglists
                      else
                        m.name
                      end
                    else
                      m.name
                    end

      member[:title] = m.name if m.name
      member[:comment] = get_comment(m)

      if m.respond_to? :markup_code
        member[:code] = m.markup_code if m.markup_code && m.markup_code != ''
      end

      if m.respond_to? :type
        member[:level] = m.type.to_sym if m.type
      end

      if m.respond_to? :visibility
        member[:visibility] = m.visibility.to_sym if m.visibility
      end

      yield member

      members << member
    end

    members
  end

  def build_indicators(object)
    indicators = []

    case object[:kind]
    when :module
      indicators << :indicatorKindModule
    when :class
      indicators << :indicatorKindClass
    when :included
      indicators << :indicatorKindIncluded
    when :extended
      indicators << :indicatorKindExtended
    when :constant
      indicators << :indicatorKindConstant
    when :method
      indicators << if object[:level] == :class
                      :indicatorKindClassMethod
                    else
                      :indicatorKindInstanceMethod
                    end
    when :attribute
      indicators << if object[:level] == :class
                      :indicatorKindClassAttribute
                    else
                      :indicatorKindInstanceAttribute
                    end
    end

    case object[:visibility]
    when :public
      indicators << :indicatorVisibilityPublic
    when :private
      indicators << :indicatorVisibilityPrivate
    when :protected
      indicators << :indicatorVisibilityProtected
    end

    indicators
  end

  def with_indicators(array)
    array.each do |object|
      object[:indicators] = build_indicators(object)
    end
    array
  end

  def get_comment(object)
    if object.comment.respond_to? :text
      object.description.strip
    else
      object.comment
    end
  end

  def get_class_kind(class_name)
    if @store.all_modules.select { |m| m.full_name == class_name }.size == 1
      :module
    else
      :class
    end
  end

  def get_member_group(member)
    case member[:kind]
    when :method
      case member[:level]
      when :instance
        {
          title: 'Instance Methods',
          kind:  :method,
          level: :instance
        }
      when :class
        {
          title: 'Class Methods',
          kind:  :method,
          level: :class
        }
      end
    when :attribute
      case member[:level]
      when :instance
        {
          title: 'Instance Attributes',
          kind:  :attribute,
          level: :instance
        }
      when :class
        {
          title: 'Class Attributes',
          kind:  :attribute,
          level: :class
        }
      end
    when :constant
      {
        title: 'Constants',
        kind:  :constant
      }
    when :extended
      {
        title: 'Extend Modules',
        kind:  :extended
      }
    when :included
      {
        title: 'Include Modules',
        kind:  :included
      }
    end
  end

  def skip_class?(class_name)
    if @options.sf_filter_classes
      @options.sf_filter_classes.match(class_name).nil?
    else
      false
    end
  end

  def skip_member?(member_name)
    if @options.sf_filter_members
      @options.sf_filter_members.match(member_name).nil?
    else
      false
    end
  end
end
