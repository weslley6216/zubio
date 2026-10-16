module Result
  class Success
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def success? = true

    def failure? = false
  end

  class Failure
    attr_reader :reason, :record

    def initialize(reason, record: nil)
      @reason = reason
      @record = record
    end

    def success? = false

    def failure? = true
  end
end
