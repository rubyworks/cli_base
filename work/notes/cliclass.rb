


  class MyCline < CliClass

    # Example of subcommand.
    def show(*args)
      # ...
    end

    def run(file)
      # ...
    end

    # example '--loadpath' option for run
    def run_loadpath(paths)

    end

    # example of  '-I' option for run
    alias_method :run_I, :run_loadpath

    # example '--help' option for run
    def run_help
      # ...
    end

    # example of a global '--help' option.
    def _help
      puts "RTFM"; exit
    end

    # example of a global '--verbose' option.
    def _verbose
      @verbose = true
    end

    alias_method :_v, :_verbose

  end


# OR

# This is basically comandable.

  class MyCline < CliClass

    # Example of subcommand.
    def show(*args)
      # ...
    end

    # Example of another subcommand.
    def run(file)
      # ...
    end

    # example '--loadpath' option for run
    def run_loadpath=(paths)

    end

    # example of  '-I' option for run
    alias_method :run_I=, :run_loadpath=

    # example '--help' option for run
    def run_help=(value=true)
      # ...
    end

    # example of a global '--verbose' option.
    def help=(value)
      if value
        puts "RTFM"; exit
      end
    end

    # example of a global '--verbose' option.
    def verbose=(value)
      @verbose = value
    end

    alias_method :v=, :verbose=

  end

