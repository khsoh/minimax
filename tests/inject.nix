let
  hello = "Hello world!";
in
{
  myjs =
    # javascript
    ''
      var myvar = "${hello}";
      console.log(`embedded: ''${myvar}`);
    '';

  mybash =
    # bash
    ''
      # Will test for heredoc within bash
      echo "Hello $hello"
      osascript -l JavaScript <<'EOF_javascript'
        var myvar = "${hello}";
        console.log(`embedded: ''${myvar}`);
      EOF_javascript
    '';
}
