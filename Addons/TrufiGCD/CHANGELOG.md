# TrufiGCD

## [v1.36](https://github.com/Trufi/TrufiGCD/tree/v1.36) (2026-01-28)
[Full Changelog](https://github.com/Trufi/TrufiGCD/compare/v1.35...v1.36) [Previous Releases](https://github.com/Trufi/TrufiGCD/releases)

- Midnight Compatibility (#28)  
    * update toc  
    * use RegisterUnitEvent, use EventUtil.ContinueOnAddOnLoaded  
    * add IsMidnight constant and only conditionally add unit/layout types  
    * make interfaceOptions\_AddCategory midnight compatible  
    * do the same with unit settings  
    * use category:GetID()  
    * only conditionally add units to layout type mapping too  
    * revert autosave doing stupid things  
    * Code style fixes  
    * Add missing IsMidNight const and fix interface\_AddCategory  
    * Fix toc  
    * Fix settings openning from compartment menu  
    ---------  
    Co-authored-by: Mstislav Zhivodkov <stevemyz@gmail.com>  