"""Labeled controls for the intake form."""

import from ..theme {
    CHOICE,
    CHOICE_INPUT,
    CHOICES,
    CONTROL,
    CONTROL_OFF,
    FIELD,
    HINT,
    LABEL,
    LEGEND,
    OPT,
    REQ
}

def:pub TextField(
    id: str,
    label: str,
    value: str,
    onValue: Callable[[str], None],
    required: bool = False,
    hint: str = "",
    placeholder: str = "",
    input_mode: str = "text",
    disabled: bool = False,
    suggestions: list[str] = []
) -> JsxElement {
    def on_change(e: ChangeEvent) {
        onValue(e.target.value);
    }
    list_id = id + "-suggestions";
    box = CONTROL;
    if disabled {
        box = CONTROL_OFF;
    }
    <div style={FIELD}>
        <label htmlFor={id} style={LABEL}>
            {label}
            {<span style={REQ}>Required</span> if required else <span style={OPT}>Optional</span>}
        </label>
        <input
            id={id}
            name={id}
            type="text"
            inputMode={input_mode}
            value={value}
            placeholder={placeholder}
            disabled={disabled}
            aria-required={required}
            aria-describedby={id + "-hint"}
            list={list_id if suggestions else ""}
            style={box}
            onChange={on_change}
        />
        {if suggestions {
            <datalist id={list_id}>
                {for name in suggestions {
                    <option key={name} value={name}>{name}</option>
                }}
            </datalist>
        }}
        <p id={id + "-hint"} style={HINT}>{hint}</p>
    </div>
}

def:pub SelectField(
    id: str,
    label: str,
    value: str,
    onValue: Callable[[str], None],
    required: bool = False,
    hint: str = "",
    children: any = None
) -> JsxElement {
    def on_change(e: ChangeEvent) {
        onValue(e.target.value);
    }
    <div style={FIELD}>
        <label htmlFor={id} style={LABEL}>
            {label}
            {<span style={REQ}>Required</span> if required else <span style={OPT}>Optional</span>}
        </label>
        <select
            id={id}
            name={id}
            value={value}
            aria-required={required}
            aria-describedby={id + "-hint"}
            style={CONTROL}
            onChange={on_change}
        >
            {children}
        </select>
        <p id={id + "-hint"} style={HINT}>{hint}</p>
    </div>
}

def:pub RadioLine(
    name: str,
    value: str,
    current: str,
    label: str,
    onValue: Callable[[str], None]
) -> JsxElement {
    def on_change(e: ChangeEvent) {
        onValue(e.target.value);
    }
    <label style={CHOICE}>
        <input
            type="radio"
            name={name}
            value={value}
            checked={current == value}
            style={CHOICE_INPUT}
            onChange={on_change}
        />
        <span>{label}</span>
    </label>
}

def:pub CheckField(
    id: str,
    label: str,
    checked: bool,
    onChecked: Callable[[bool], None]
) -> JsxElement {
    def on_change(e: ChangeEvent) {
        onChecked(e.target.checked);
    }
    <label style={CHOICE} htmlFor={id}>
        <input
            id={id}
            name={id}
            type="checkbox"
            checked={checked}
            style={CHOICE_INPUT}
            onChange={on_change}
        />
        <span>{label}</span>
    </label>
}

def:pub Importance(
    name: str,
    value: str,
    onValue: Callable[[str], None]
) -> JsxElement {
    <fieldset style={{"margin": "0", "padding": "0", "border": "0"}}>
        <legend style={LEGEND}>How important is this?</legend>
        <div style={CHOICES}>
            <RadioLine name={name} value="must" current={value} label="Must have" onValue={onValue} />
            <RadioLine name={name} value="nice" current={value} label="Nice to have" onValue={onValue} />
            <RadioLine name={name} value="ignore" current={value} label="Don't care" onValue={onValue} />
        </div>
    </fieldset>
}
