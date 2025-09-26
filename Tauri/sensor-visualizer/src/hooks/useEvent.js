import {useEffect} from "react";

function useEvent(events, handler, passive = false) {
    const targets = {
        click: document.body,
        keydown: document,
        keypress: document,
        keyup: document,
    };
    events.split(' ').forEach(event => {
        const target = targets[event] || window;
        useEffect(() => {
            target.addEventListener(event, handler, passive);
            return function cleanup() {
                target.removeEventListener(event, handler);
            };
        }, [handler, passive]);
    });
}

export default useEvent;