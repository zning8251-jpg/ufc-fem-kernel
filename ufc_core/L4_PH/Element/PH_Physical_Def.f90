!===============================================================================
! MODULE: PH_Physical_Def
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Def
! BRIEF:  SI physical constants and unit conversion utilities
!===============================================================================
MODULE PH_Physical_Def
    USE IF_Base_Def, ONLY: wp
    IMPLICIT NONE
    PRIVATE
    
    ! ==========================================================================
    ! PUBLIC INTERFACE
    ! ==========================================================================
    ! Physical constants
    PUBLIC :: PH_PHYS_GRAVITY, PH_PHYS_STEFAN_BOLTZMANN, PH_PHYS_BOLTZMANN_CONST, &
              PH_PHYS_GAS_CONSTANT, PH_PHYS_ABSOLUTE_ZERO, PH_PHYS_ABSOLUTE_ZERO_K, &
              PH_PHYS_SPEED_OF_LIGHT, PH_PHYS_VACUUM_PERMITTIVITY, PH_PHYS_VACUUM_PERMEABILITY, &
              PH_PHYS_WATER_DENSITY, PH_PHYS_WATER_VISCOSITY, &
              PH_PHYS_AIR_DENSITY, PH_PHYS_AIR_VISCOSITY
    
    ! Unit conversion functions
    PUBLIC :: PH_Const_Convert_Energy, PH_Const_Convert_Force, &
              PH_Const_Convert_Length, PH_Const_Convert_Mass, &
              PH_Const_Convert_Pressure, PH_Const_Convert_Temperature
    
    ! Unit conversion constants
    PUBLIC :: PH_CONV_INCH_TO_METER, PH_CONV_FOOT_TO_METER, &
              PH_CONV_METER_TO_INCH, PH_CONV_METER_TO_FOOT, &
              PH_CONV_POUND_TO_KG, PH_CONV_KG_TO_POUND, &
              PH_CONV_POUND_FORCE_TO_NEWTON, PH_CONV_NEWTON_TO_POUND_FORCE, &
              PH_CONV_PSI_TO_PA, PH_CONV_PA_TO_PSI, &
              PH_CONV_ATM_TO_PA, PH_CONV_PA_TO_ATM, &
              PH_CONV_BAR_TO_PA, PH_CONV_PA_TO_BAR, &
              PH_CONV_KELVIN_TO_CELSIUS, PH_CONV_CELSIUS_TO_KELVIN, &
              PH_CONV_FAHRENHEIT_TO_CELSIUS_SCALE, PH_CONV_FAHRENHEIT_TO_CELSIUS_OFFSET, &
              PH_CONV_CELSIUS_TO_FAHRENHEIT_SCALE, PH_CONV_CELSIUS_TO_FAHRENHEIT_OFFSET, &
              PH_CONV_CALORIE_TO_JOULE, PH_CONV_JOULE_TO_CALORIE, &
              PH_CONV_BTU_TO_JOULE, PH_CONV_JOULE_TO_BTU

    ! ==========================================================================
    ! PHYSICAL CONSTANTS (SI Units, CODATA 2018)
    ! ==========================================================================
    ! Gravitational acceleration
    REAL(wp), PARAMETER :: PH_PHYS_GRAVITY = 9.80665_wp               ! m/s² (standard)
    
    ! Thermodynamics
    REAL(wp), PARAMETER :: PH_PHYS_STEFAN_BOLTZMANN = 5.670374419e-8_wp   ! W/(m²·K ?
    REAL(wp), PARAMETER :: PH_PHYS_BOLTZMANN_CONST = 1.380649e-23_wp      ! J/K
    REAL(wp), PARAMETER :: PH_PHYS_GAS_CONSTANT = 8.314462618_wp          ! J/(mol·K)
    REAL(wp), PARAMETER :: PH_PHYS_ABSOLUTE_ZERO = -273.15_wp             ! °C
    REAL(wp), PARAMETER :: PH_PHYS_ABSOLUTE_ZERO_K = 0.0_wp               ! K
    
    ! Electromagnetics
    REAL(wp), PARAMETER :: PH_PHYS_SPEED_OF_LIGHT = 299792458.0_wp        ! m/s
    REAL(wp), PARAMETER :: PH_PHYS_VACUUM_PERMITTIVITY = 8.8541878128e-12_wp ! F/m
    REAL(wp), PARAMETER :: PH_PHYS_VACUUM_PERMEABILITY = 1.25663706212e-6_wp ! H/m
    
    ! Water properties (at 20°C, 1 atm)
    REAL(wp), PARAMETER :: PH_PHYS_WATER_DENSITY = 998.2_wp               ! kg/m³
    REAL(wp), PARAMETER :: PH_PHYS_WATER_VISCOSITY = 1.002e-3_wp          ! Pa·s
    
    ! Air properties (at 20°C, 1 atm)
    REAL(wp), PARAMETER :: PH_PHYS_AIR_DENSITY = 1.204_wp                 ! kg/m³
    REAL(wp), PARAMETER :: PH_PHYS_AIR_VISCOSITY = 1.825e-5_wp           ! Pa·s

    ! ==========================================================================
    ! UNIT CONVERSION FACTORS
    ! ==========================================================================
    ! Length
    REAL(wp), PARAMETER :: PH_CONV_INCH_TO_METER = 0.0254_wp              ! m/in
    REAL(wp), PARAMETER :: PH_CONV_FOOT_TO_METER = 0.3048_wp              ! m/ft
    REAL(wp), PARAMETER :: PH_CONV_METER_TO_INCH = 39.37007874_wp         ! in/m
    REAL(wp), PARAMETER :: PH_CONV_METER_TO_FOOT = 3.280839895_wp         ! ft/m
    
    ! Mass
    REAL(wp), PARAMETER :: PH_CONV_POUND_TO_KG = 0.45359237_wp            ! kg/lb
    REAL(wp), PARAMETER :: PH_CONV_KG_TO_POUND = 2.20462262185_wp         ! lb/kg
    
    ! Force
    REAL(wp), PARAMETER :: PH_CONV_POUND_FORCE_TO_NEWTON = 4.4482216152605_wp ! N/lbf
    REAL(wp), PARAMETER :: PH_CONV_NEWTON_TO_POUND_FORCE = 0.2248089431_wp    ! lbf/N
    
    ! Pressure/Stress
    REAL(wp), PARAMETER :: PH_CONV_PSI_TO_PA = 6894.757293178_wp          ! Pa/psi
    REAL(wp), PARAMETER :: PH_CONV_PA_TO_PSI = 1.4503773773e-4_wp         ! psi/Pa
    REAL(wp), PARAMETER :: PH_CONV_ATM_TO_PA = 101325.0_wp                ! Pa/atm
    REAL(wp), PARAMETER :: PH_CONV_PA_TO_ATM = 9.86923266716e-6_wp        ! atm/Pa
    REAL(wp), PARAMETER :: PH_CONV_BAR_TO_PA = 1.0e5_wp                   ! Pa/bar
    REAL(wp), PARAMETER :: PH_CONV_PA_TO_BAR = 1.0e-5_wp                  ! bar/Pa
    
    ! Temperature
    REAL(wp), PARAMETER :: PH_CONV_KELVIN_TO_CELSIUS = -273.15_wp         ! °C offset
    REAL(wp), PARAMETER :: PH_CONV_CELSIUS_TO_KELVIN = 273.15_wp          ! K offset
    REAL(wp), PARAMETER :: PH_CONV_FAHRENHEIT_TO_CELSIUS_SCALE = 5.0_wp / 9.0_wp
    REAL(wp), PARAMETER :: PH_CONV_FAHRENHEIT_TO_CELSIUS_OFFSET = -32.0_wp
    REAL(wp), PARAMETER :: PH_CONV_CELSIUS_TO_FAHRENHEIT_SCALE = 9.0_wp / 5.0_wp
    REAL(wp), PARAMETER :: PH_CONV_CELSIUS_TO_FAHRENHEIT_OFFSET = 32.0_wp
    
    ! Energy
    REAL(wp), PARAMETER :: PH_CONV_CALORIE_TO_JOULE = 4.184_wp            ! J/cal
    REAL(wp), PARAMETER :: PH_CONV_JOULE_TO_CALORIE = 0.239005736_wp      ! cal/J
    REAL(wp), PARAMETER :: PH_CONV_BTU_TO_JOULE = 1055.05585262_wp        ! J/BTU
    REAL(wp), PARAMETER :: PH_CONV_JOULE_TO_BTU = 9.47817120313e-4_wp     ! BTU/J

CONTAINS

    !> @brief Convert energy units (J, cal, BTU)
    !! @param[in] value Input value
    !! @param[in] from_unit Source unit ('J', 'cal', 'BTU')
    !! @param[in] to_unit Target unit ('J', 'cal', 'BTU')
    !! @return Converted value
    REAL(wp) FUNCTION PH_Const_Convert_Energy(value, from_unit, to_unit) RESULT(converted)
        REAL(wp), INTENT(IN) :: value
        CHARACTER(len=*), INTENT(IN) :: from_unit, to_unit
        
        REAL(wp) :: value_J
        
        ! Convert to Joules first
        SELECT CASE (from_unit)
            CASE ('J', 'joule', 'joules')
                value_J = value
            CASE ('cal', 'calorie', 'calories')
                value_J = value * PH_CONV_CALORIE_TO_JOULE
            CASE ('BTU', 'btu')
                value_J = value * PH_CONV_BTU_TO_JOULE
            CASE DEFAULT
                value_J = value  ! Assume J
        END SELECT
        
        ! Convert from J to target unit
        SELECT CASE (to_unit)
            CASE ('J', 'joule', 'joules')
                converted = value_J
            CASE ('cal', 'calorie', 'calories')
                converted = value_J * PH_CONV_JOULE_TO_CALORIE
            CASE ('BTU', 'btu')
                converted = value_J * PH_CONV_JOULE_TO_BTU
            CASE DEFAULT
                converted = value_J  ! Assume J
        END SELECT
    END FUNCTION PH_Const_Convert_Energy

    !> @brief Convert force units (N, lbf)
    !! @param[in] value Input value
    !! @param[in] from_unit Source unit ('N', 'lbf', 'pound_force')
    !! @param[in] to_unit Target unit ('N', 'lbf', 'pound_force')
    !! @return Converted value
    REAL(wp) FUNCTION PH_Const_Convert_Force(value, from_unit, to_unit) RESULT(converted)
        REAL(wp), INTENT(IN) :: value
        CHARACTER(len=*), INTENT(IN) :: from_unit, to_unit
        
        REAL(wp) :: value_N
        
        ! Convert to Newtons first
        SELECT CASE (from_unit)
            CASE ('N', 'newton', 'newtons')
                value_N = value
            CASE ('lbf', 'pound_force', 'pounds_force')
                value_N = value * PH_CONV_POUND_FORCE_TO_NEWTON
            CASE DEFAULT
                value_N = value  ! Assume N
        END SELECT
        
        ! Convert from N to target unit
        SELECT CASE (to_unit)
            CASE ('N', 'newton', 'newtons')
                converted = value_N
            CASE ('lbf', 'pound_force', 'pounds_force')
                converted = value_N * PH_CONV_NEWTON_TO_POUND_FORCE
            CASE DEFAULT
                converted = value_N  ! Assume N
        END SELECT
    END FUNCTION PH_Const_Convert_Force

    !> @brief Convert length units (m, in, ft)
    !! @param[in] value Input value
    !! @param[in] from_unit Source unit ('m', 'in', 'ft')
    !! @param[in] to_unit Target unit ('m', 'in', 'ft')
    !! @return Converted value
    REAL(wp) FUNCTION PH_Const_Convert_Length(value, from_unit, to_unit) RESULT(converted)
        REAL(wp), INTENT(IN) :: value
        CHARACTER(len=*), INTENT(IN) :: from_unit, to_unit
        
        REAL(wp) :: value_m
        
        ! Convert to meters first
        SELECT CASE (from_unit)
            CASE ('m', 'meter', 'meters')
                value_m = value
            CASE ('in', 'inch', 'inches')
                value_m = value * PH_CONV_INCH_TO_METER
            CASE ('ft', 'foot', 'feet')
                value_m = value * PH_CONV_FOOT_TO_METER
            CASE DEFAULT
                value_m = value  ! Assume meters
        END SELECT
        
        ! Convert from meters to target unit
        SELECT CASE (to_unit)
            CASE ('m', 'meter', 'meters')
                converted = value_m
            CASE ('in', 'inch', 'inches')
                converted = value_m * PH_CONV_METER_TO_INCH
            CASE ('ft', 'foot', 'feet')
                converted = value_m * PH_CONV_METER_TO_FOOT
            CASE DEFAULT
                converted = value_m  ! Assume meters
        END SELECT
    END FUNCTION PH_Const_Convert_Length

    !> @brief Convert mass units (kg, lb)
    !! @param[in] value Input value
    !! @param[in] from_unit Source unit ('kg', 'lb', 'pound')
    !! @param[in] to_unit Target unit ('kg', 'lb', 'pound')
    !! @return Converted value
    REAL(wp) FUNCTION PH_Const_Convert_Mass(value, from_unit, to_unit) RESULT(converted)
        REAL(wp), INTENT(IN) :: value
        CHARACTER(len=*), INTENT(IN) :: from_unit, to_unit
        
        REAL(wp) :: value_kg
        
        ! Convert to kg first
        SELECT CASE (from_unit)
            CASE ('kg', 'kilogram', 'kilograms')
                value_kg = value
            CASE ('lb', 'pound', 'pounds')
                value_kg = value * PH_CONV_POUND_TO_KG
            CASE DEFAULT
                value_kg = value  ! Assume kg
        END SELECT
        
        ! Convert from kg to target unit
        SELECT CASE (to_unit)
            CASE ('kg', 'kilogram', 'kilograms')
                converted = value_kg
            CASE ('lb', 'pound', 'pounds')
                converted = value_kg * PH_CONV_KG_TO_POUND
            CASE DEFAULT
                converted = value_kg  ! Assume kg
        END SELECT
    END FUNCTION PH_Const_Convert_Mass

    !> @brief Convert pressure/stress units (Pa, psi, atm, bar)
    !! @param[in] value Input value
    !! @param[in] from_unit Source unit ('Pa', 'psi', 'atm', 'bar')
    !! @param[in] to_unit Target unit ('Pa', 'psi', 'atm', 'bar')
    !! @return Converted value
    REAL(wp) FUNCTION PH_Const_Convert_Pressure(value, from_unit, to_unit) RESULT(converted)
        REAL(wp), INTENT(IN) :: value
        CHARACTER(len=*), INTENT(IN) :: from_unit, to_unit
        
        REAL(wp) :: value_Pa
        
        ! Convert to Pascals first
        SELECT CASE (from_unit)
            CASE ('Pa', 'pascal', 'pascals')
                value_Pa = value
            CASE ('psi', 'PSI')
                value_Pa = value * PH_CONV_PSI_TO_PA
            CASE ('atm', 'atmosphere', 'atmospheres')
                value_Pa = value * PH_CONV_ATM_TO_PA
            CASE ('bar', 'bars')
                value_Pa = value * PH_CONV_BAR_TO_PA
            CASE DEFAULT
                value_Pa = value  ! Assume Pa
        END SELECT
        
        ! Convert from Pa to target unit
        SELECT CASE (to_unit)
            CASE ('Pa', 'pascal', 'pascals')
                converted = value_Pa
            CASE ('psi', 'PSI')
                converted = value_Pa * PH_CONV_PA_TO_PSI
            CASE ('atm', 'atmosphere', 'atmospheres')
                converted = value_Pa * PH_CONV_PA_TO_ATM
            CASE ('bar', 'bars')
                converted = value_Pa * PH_CONV_PA_TO_BAR
            CASE DEFAULT
                converted = value_Pa  ! Assume Pa
        END SELECT
    END FUNCTION PH_Const_Convert_Pressure

    !> @brief Convert temperature units (K, C, F)
    !! @param[in] value Input value
    !! @param[in] from_unit Source unit ('K', 'C', 'F', 'kelvin', 'celsius', 'fahrenheit')
    !! @param[in] to_unit Target unit ('K', 'C', 'F', 'kelvin', 'celsius', 'fahrenheit')
    !! @return Converted value
    REAL(wp) FUNCTION PH_Const_Convert_Temperature(value, from_unit, to_unit) RESULT(converted)
        REAL(wp), INTENT(IN) :: value
        CHARACTER(len=*), INTENT(IN) :: from_unit, to_unit
        
        REAL(wp) :: value_K
        
        ! Convert to Kelvin first
        SELECT CASE (from_unit)
            CASE ('K', 'kelvin', 'Kelvin')
                value_K = value
            CASE ('C', 'celsius', 'Celsius')
                value_K = value + PH_CONV_CELSIUS_TO_KELVIN
            CASE ('F', 'fahrenheit', 'Fahrenheit')
                value_K = (value + ABS(PH_CONV_FAHRENHEIT_TO_CELSIUS_OFFSET)) * &
                          PH_CONV_FAHRENHEIT_TO_CELSIUS_SCALE + PH_CONV_CELSIUS_TO_KELVIN
            CASE DEFAULT
                value_K = value  ! Assume K
        END SELECT
        
        ! Convert from K to target unit
        SELECT CASE (to_unit)
            CASE ('K', 'kelvin', 'Kelvin')
                converted = value_K
            CASE ('C', 'celsius', 'Celsius')
                converted = value_K + PH_CONV_KELVIN_TO_CELSIUS
            CASE ('F', 'fahrenheit', 'Fahrenheit')
                converted = (value_K - PH_CONV_CELSIUS_TO_KELVIN) * &
                            PH_CONV_CELSIUS_TO_FAHRENHEIT_SCALE + &
                            PH_CONV_CELSIUS_TO_FAHRENHEIT_OFFSET
            CASE DEFAULT
                converted = value_K  ! Assume K
        END SELECT
    END FUNCTION PH_Const_Convert_Temperature

END MODULE PH_Physical_Def
