"""Labeled controls for the intake form."""

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
    <div className="field">
        <label htmlFor={id}>
            {label}
            {<span className="req">Required</span> if required else <span className="opt">Optional</span>}
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
            onChange={on_change}
        />
        {if suggestions {
            <datalist id={list_id}>
                {for name in suggestions {
                    <option key={name} value={name}>{name}</option>
                }}
            </datalist>
        }}
        <p id={id + "-hint"} className="hint">{hint}</p>
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
    <div className="field">
        <label htmlFor={id}>
            {label}
            {<span className="req">Required</span> if required else <span className="opt">Optional</span>}
        </label>
        <select
            id={id}
            name={id}
            value={value}
            aria-required={required}
            aria-describedby={id + "-hint"}
            onChange={on_change}
        >
            {children}
        </select>
        <p id={id + "-hint"} className="hint">{hint}</p>
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
    <label className="choice">
        <input
            type="radio"
            name={name}
            value={value}
            checked={current == value}
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
    <label className="check" htmlFor={id}>
        <input
            id={id}
            name={id}
            type="checkbox"
            checked={checked}
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
    <fieldset className="importance">
        <legend>How important is this?</legend>
        <RadioLine name={name} value="must" current={value} label="Must have" onValue={onValue} />
        <RadioLine name={name} value="nice" current={value} label="Nice to have" onValue={onValue} />
        <RadioLine name={name} value="ignore" current={value} label="Don't care" onValue={onValue} />
    </fieldset>
}
