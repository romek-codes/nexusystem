{ config, lib, ... }:
let
  lua = lib.generators.mkLuaInline;
  animationSpeed = config.theme.animation-speed;

  animationDuration = if animationSpeed == "slow" then
    4
  else if animationSpeed == "medium" then
    2.5
  else
    1.5;
  borderDuration = if animationSpeed == "slow" then
    10
  else if animationSpeed == "medium" then
    6
  else
    3;

  bezierCurve = name: x0: y0: x1: y1: {
    _args = [
      name
      {
        type = "bezier";
        points = lua "{ { ${toString x0}, ${toString y0} }, { ${toString x1}, ${toString y1} } }";
      }
    ];
  };

  mkAnimation =
    leaf: speed: curve: style:
    {
      inherit leaf speed;
      enabled = true;
      bezier = curve;
    }
    // lib.optionalAttrs (style != null) { inherit style; };
in {
  wayland.windowManager.hyprland.settings = {
    config.animations.enabled = true;

    curve = [
      (bezierCurve "linear" 0 0 1 1)
      (bezierCurve "md3_standard" 0.2 0 0 1)
      (bezierCurve "md3_decel" 0.05 0.7 0.1 1)
      (bezierCurve "md3_accel" 0.3 0 0.8 0.15)
      (bezierCurve "overshot" 0.05 0.9 0.1 1.1)
      (bezierCurve "crazyshot" 0.1 1.5 0.76 0.92)
      (bezierCurve "hyprnostretch" 0.05 0.9 0.1 1.0)
      (bezierCurve "menu_decel" 0.1 1 0 1)
      (bezierCurve "menu_accel" 0.38 0.04 1 0.07)
      (bezierCurve "easeInOutCirc" 0.85 0 0.15 1)
      (bezierCurve "easeOutCirc" 0 0.55 0.45 1)
      (bezierCurve "easeOutExpo" 0.16 1 0.3 1)
      (bezierCurve "softAcDecel" 0.26 0.26 0.15 1)
      (bezierCurve "md2" 0.4 0 0.2 1)
    ];

    animation = [
      (mkAnimation "windows" animationDuration "md3_decel" "popin 60%")
      (mkAnimation "windowsIn" animationDuration "md3_decel" "popin 60%")
      (mkAnimation "windowsOut" animationDuration "md3_accel" "popin 60%")
      (mkAnimation "border" borderDuration "default" null)
      (mkAnimation "fade" animationDuration "md3_decel" null)
      (mkAnimation "layersIn" animationDuration "menu_decel" "slide")
      (mkAnimation "layersOut" animationDuration "menu_accel" null)
      (mkAnimation "fadeLayersIn" animationDuration "menu_decel" null)
      (mkAnimation "fadeLayersOut" animationDuration "menu_accel" null)
      (mkAnimation "workspaces" animationDuration "menu_decel" "slide")
      (mkAnimation "specialWorkspace" animationDuration "md3_decel" "slidevert")
    ];
  };
}
