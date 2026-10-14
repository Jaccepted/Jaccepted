"""Labeled controls for the intake form."""

import from ..theme {
    CHOICE,
    CHOICE_INPUT,
    CHOICES,
    CONTROL,
    CONTROL_OFF,
    CONTROL_OPEN,
    FIELD,
    HINT,
    LABEL,
    LEGEND,
    OPT,
    REQ,
    SUGGEST_ITEM,
    SUGGEST_ITEM_ON,
    SUGGEST_LIST
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
    has open: bool = False;
    has active: int = -1;
    list_id = id + "-suggestions";
    wanted = value.strip().lower();
    matches = [name for name in suggestions if wanted in name.lower() and name.lower() != wanted];
    showing = open and not disabled and len(matches) > 0;
    def on_change(e: ChangeEvent) {
        onValue(e.target.value);
        open = True;
        active = -1;
    }
    def on_focus(e: FocusEvent) {
        open = True;
    }
    def on_blur(e: FocusEvent) {
        open = False;
        active = -1;
    }
    def pick(name: str) {
        onValue(name);
        open = False;
        active = -1;
    }
    def on_key(e: KeyboardEvent) {
        if not matches {
            return;
        }
        if e.key == "ArrowDown" {
            e.preventDefault();
            open = True;
            active = (active + 1) % len(matches);
        } elif e.key == "ArrowUp" {
            e.preventDefault();
            open = True;
            active = len(matches) - 1 if active <= 0 else active - 1;
        } elif e.key == "Enter" and showing and active >= 0 {
            e.preventDefault();
            pick(matches[active]);
        } elif e.key == "Escape" and showing {
            e.preventDefault();
            open = False;
            active = -1;
        }
    }
    # Keep focus in the input so the click lands before blur closes the list.
    def hold_focus(e: MouseEvent) {
        e.preventDefault();
    }
    box = CONTROL;
    if disabled {
        box = CONTROL_OFF;
    } elif showing {
        box = {**CONTROL, **CONTROL_OPEN};
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
            autoComplete={"off" if suggestions else "on"}
            role={"combobox" if suggestions else "textbox"}
            aria-autocomplete={"list" if suggestions else "none"}
            aria-expanded={showing}
            aria-controls={list_id if showing else ""}
            aria-activedescendant={(list_id + "-" + str(active)) if showing and active >= 0 else ""}
            aria-required={required}
            aria-describedby={id + "-hint"}
            style={box}
            onChange={on_change}
            onFocus={on_focus}
            onBlur={on_blur}
            onKeyDown={on_key}
        />
        {if showing {
            <ul id={list_id} role="listbox" aria-label={label} style={SUGGEST_LIST}>
                {for (index, name) in enumerate(matches) {
                    <li
                        key={name}
                        id={list_id + "-" + str(index)}
                        role="option"
                        aria-selected={index == active}
                        style={SUGGEST_ITEM_ON if index == active else SUGGEST_ITEM}
                        onMouseDown={hold_focus}
                        onMouseEnter={lambda (e: MouseEvent) { active = index; }}
                        onClick={lambda (e: MouseEvent) { pick(name); }}
                    >
                        {name}
                    </li>
                }}
            </ul>
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
