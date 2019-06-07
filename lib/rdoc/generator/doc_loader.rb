# DocLoader reads RDoc documentation from RDoc store and builds a hash that
# will be passed to HTML template or written to JSON file.
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

    classes = classes.reject do |klass|
      skip_class? klass.full_name
    end

    class_list = classes.map do |klass|
      {
        id:      klass.full_name.strip,
        title:   klass.full_name,
        kind:    get_class_kind(klass.full_name),
        comment: get_comment(klass),
        groups:  build_groups(klass)
      }
    end

    stable_sort_by! class_list do |klass|
      klass[:id]
    end

    with_labels class_list
  end

  def build_groups(klass)
    members = build_members(klass)
    groups = {}

    members.each do |member|
      group = get_builtin_group(member)
      next unless group

      group_id = make_id(klass, group[:type].to_s)

      unless groups.include? group_id
        groups[group_id] = group.merge(
          id: group_id,
          members: []
        )
      end

      groups[group_id][:members] << member
    end

    group_list = groups.values

    group_list.each do |group|
      stable_sort_by! group[:members] do |member|
        member[:id]
      end
    end

    stable_sort_by! group_list do |group|
      builtin_group_order.index group[:type]
    end

    group_list
  end

  def build_members(klass)
    members = []

    method_members = build_members_from_list klass, klass.method_list do |member|
      member[:kind] = :method
    end

    attr_members = build_members_from_list klass, klass.attributes do |member|
      member[:kind] = :attribute
    end

    const_members = build_members_from_list klass, klass.constants do |member|
      member[:kind] = :constant
    end

    extends_members = build_members_from_list klass, klass.extends do |member|
      member[:kind] = :extended
    end

    include_members = build_members_from_list klass, klass.includes do |member|
      member[:kind] = :included
    end

    members.push(*method_members)
    members.push(*attr_members)
    members.push(*const_members)
    members.push(*extends_members)
    members.push(*include_members)

    with_labels members
  end

  def build_members_from_list(klass, member_list)
    members = []

    member_list.each do |m|
      next if skip_member? m.name

      member = {}

      member[:id] = make_id(klass, m.name)
      member[:title] = get_title(m)
      member[:signature] = get_signature(m)
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

  def build_labels(object)
    labels = []

    case object[:kind]
    when :module, :class, :constant, :included, :extended
      labels << {
        id:    object[:kind].capitalize,
        title: object[:kind].to_s
      }

    when :method
      labels << if object[:level] == :class
                  {
                    id:    'ClassMethod',
                    title: 'class method'
                  }
                else
                  {
                    id:    'InstanceMethod',
                    title: 'instance method'
                  }
                end

    when :attribute
      labels << if object[:level] == :class
                  {
                    id:    'ClassAttribute',
                    title: 'class attribute'
                  }
                else
                  {
                    id:    'InstanceAttribute',
                    title: 'instance attribute'
                  }
                end
    end

    if object[:visibility]
      labels << {
        id:    object[:visibility].capitalize,
        title: object[:visibility].to_s
      }
    end

    labels
  end

  def with_labels(array)
    array.each do |object|
      object[:labels] = build_labels(object)
    end
    array
  end

  def make_id(klass, name)
    klass.full_name.strip + '::' + name
  end

  def get_title(object)
    object.name
  end

  def get_signature(object)
    if object.respond_to? :arglists
      return object.arglists if object.arglists
    end
    ''
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

  def builtin_group_order
    %i[
      ExtendedClasses
      IncludedModules
      Constants
      ClassAttributes
      ClassMethods
      InstanceAttributes
      InstanceMethods
    ]
  end

  def get_builtin_group(member)
    case member[:kind]
    when :method
      case member[:level]
      when :instance
        {
          title: 'Instance Methods',
          type:  :InstanceMethods,
          kind:  :method,
          level: :instance
        }
      when :class
        {
          title: 'Class Methods',
          type:  :ClassMethods,
          kind:  :method,
          level: :class
        }
      end
    when :attribute
      case member[:level]
      when :instance
        {
          title: 'Instance Attributes',
          type:  :InstanceAttributes,
          kind:  :attribute,
          level: :instance
        }
      when :class
        {
          title: 'Class Attributes',
          type:  :ClassAttributes,
          kind:  :attribute,
          level: :class
        }
      end
    when :constant
      {
        title: 'Constants',
        type:  :Constants,
        kind:  :constant
      }
    when :extended
      {
        title: 'Extended Classes',
        type:  :ExtendedClasses,
        kind:  :extended
      }
    when :included
      {
        title: 'Included Modules',
        type:  :IncludedModules,
        kind:  :included
      }
    end
  end

  def stable_sort_by!(array)
    sorted = array.each_with_index.sort_by do |e, n|
      [yield(e), n]
    end
    array.replace(sorted.map(&:first))
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
