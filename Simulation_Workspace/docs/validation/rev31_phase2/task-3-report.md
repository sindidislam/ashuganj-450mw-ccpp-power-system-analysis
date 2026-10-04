# Phase 2 Task 3 — Isolated Non-Ideal Component Models

**Task 3 Implementation Report**  
Date: 2026-09-17  
MATLAB Version: 24.1.0.2537033 (R2024a)

---

## 1. Scope & Deliverables
Task 3 implemented isolated non-ideal discrete-time simulation step functions for excitation, starting frequency converter (SFC), and station DC systems, without coupling to the load-flow solver, Simulink, or changing network physics.

Deliverables:
- [`matlab/analysis/phase2_excitation_step.m`](../../matlab/analysis/phase2_excitation_step.m): Generic static excitation/AVR with field response lag, command saturation limits, and OEL/UEL/stator limiters.
- [`matlab/analysis/phase2_sfc_step.m`](../../matlab/analysis/phase2_sfc_step.m): Static frequency converter starting model with power limits, exponential lag, and loss accounting.
- [`matlab/analysis/phase2_dc_step.m`](../../matlab/analysis/phase2_dc_step.m): Station 110 VDC system with lead-acid battery bank, terminal voltage sag ($V = V_{\text{ocv}} - I R$), coulombic charging, undervoltage/reserve cutoff, dual 20 kW chargers with duty/standby redundancy, full-SOC overcharge prevention, and DC continuous/pulse/emergency loads.
- [`matlab/tests/test_phase2_component_models.m`](../../matlab/tests/test_phase2_component_models.m): Comprehensive unit test suite covering all 3 subsystems.

---

## 2. TDD Verification Evidence
1. **RED Execution**:
   - Log: [`task-3-red.log`](task-3-red.log)
   - Result: Expected failure `Undefined function 'phase2_excitation_step' for input arguments of type 'struct'`.
2. **GREEN Execution**:
   - Log: [`task-3-green.log`](task-3-green.log)
   - Result: **49 passed, 0 failed** across all component model tests.
3. **Combined Regression Verification**:
   - Ran `test_engineering_assumptions` (9), `test_phase2_systems` (24), `test_generator_capability` (224), `test_phase2_component_models` (49), `test_generator_data` (476), `test_base_conversion` (39).
   - Result: **821 passed, 0 failed**.

---

## 3. Mathematical Formulations & Component Characteristics

### 3.1 Excitation / AVR / Limiters (`phase2_excitation_step.m`)
- **Numerical Update**: Exact exponential state transition for all first-order lags:
  $$x(t + \Delta t) = x_{\text{target}} + (x(t) - x_{\text{target}}) \cdot e^{-\Delta t / T}$$
  Guarantees numerical stability and prevents Euler instability for arbitrary $\Delta t$.
- **AVR**: $K_a = 200\text{ pu/pu}$, $T_{\text{avr}} = 0.02\text{ s}$, terminal error $e_V = V_{\text{ref}} - V_t$.
- **Command Saturation**: Commanded field voltage clamped to $[-5.0, +5.0]\text{ Efd pu}$.
- **Field Lag**: $T_e = 0.5\text{ s}$.
- **Limiters**:
  - **OEL**: Evaluates $E_{\text{fd}} / \text{rated\_field\_proxy}$ ($2.5\text{ Efd pu}$). Threshold $= 1.075\text{ pu}$ ($2.6875\text{ Efd pu}$). Lag $= 1.0\text{ s}$, gain $= 5.0$. Subtracts correction from AVR command.
  - **UEL**: Inset of $5.0\text{ MVAr}$ above source capability curve lower boundary $Q_{\min}(P)$. Lag $= 0.1\text{ s}$, gain $= 0.05\text{ pu/MVAr}$. Boosts AVR command when $Q$ falls below boundary.
  - **Stator Current Limiter**: Continuous threshold $= 1.0\text{ pu}$ current. Lag $= 0.2\text{ s}$, gain $= 5.0$. Flags active-current overload as requiring dispatch intervention.

### 3.2 Starting Frequency Converter (`phase2_sfc_step.m`)
- **Power Limiting**: Output bounded by $[0, 4.0\text{ MW}]$ (separately assumed starting cap).
- **Lag Response**: $\tau = 0.03\text{ s}$.
- **Loss Accounting**: Efficiency $\eta = 0.97$. $P_{\text{in}} = P_{\text{out}} / \eta$, $P_{\text{loss}} = P_{\text{in}} - P_{\text{out}}$.
- **Preserved Source Data**: Retains $2.28\text{ kV}$ DC link and $1876\text{ A}$ output starting current as explicit source records.

### 3.3 Station DC System (`phase2_dc_step.m`)
- **Battery**:
  - Nominal: $110\text{ VDC}$, $55$ cells, $200\text{ Ah}$.
  - Internal resistance: $R_{\text{int}} = 0.05\,\Omega$.
  - Linear OCV: $V_{\text{ocv}}(\text{SOC}) = 105 + 11 \cdot \text{SOC}$ ($105\text{ V}$ at empty, $116\text{ V}$ at full).
  - Terminal voltage sag: $V_{\text{term}} = V_{\text{ocv}} - I_{\text{batt}} \cdot R_{\text{int}}$.
  - Cutoff: Stops discharge when $V_{\text{term}} \le 105\text{ V}$ or $\text{SOC} \le 0.20$.
  - Current limits: Discharge $\le 200\text{ A}$, Charge $\le 40\text{ A}$, coulombic efficiency $0.90$.
- **Chargers**:
  - Two $20\text{ kW}$ DC units (1 duty, 1 standby).
  - Float voltage: $123.75\text{ V}$ ($2.25\text{ V/cell}$).
  - Current limit: $180\text{ A}$, response lag: $0.1\text{ s}$, efficiency: $0.925$.
  - Full-SOC Policy: Supplies load directly without forcing overcharge into the battery.
  - Standby takeover: When duty unit is unavailable, standby unit replaces it without doubling normal capacity.
- **Loads**:
  - Continuous: $2.4\text{ kW}$ (relay, control, instrumentation, comms, emergency electronics, excitation electronics).
  - Pulse loads: Trip ($2\text{ kW}$, $0.2\text{ s}$), Close ($3\text{ kW}$, $0.5\text{ s}$).
  - Emergency switched load: $5\text{ kW}$.

---

## 4. Requirement Verification & Safety Gates
- No ideal voltage sources or zero internal resistances used.
- No instantaneous controllers or infinite power capabilities assumed.
- Excitation, SFC, and Station DC systems remain strictly separated with no unverified cross-connections.
- Unchanged frozen load-flow physics and transformer providers preserved.
