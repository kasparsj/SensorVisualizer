import React, { createContext, useContext } from "react"
import { cn } from "../../lib/utils.js"

const TabsContext = createContext()

const Tabs = React.forwardRef(({ className, value, onValueChange, children, ...props }, ref) => {
  return (
    <TabsContext.Provider value={{ value, onValueChange }}>
      <div
        ref={ref}
        className={cn("w-full", className)}
        {...props}
      >
        {children}
      </div>
    </TabsContext.Provider>
  )
})
Tabs.displayName = "Tabs"

const TabsList = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "inline-flex h-10 items-center justify-center rounded-md bg-slate-100 p-1 text-slate-500 dark:bg-slate-800 dark:text-slate-400",
      className
    )}
    {...props}
  />
))
TabsList.displayName = "TabsList"

const TabsTrigger = React.forwardRef(({ className, value: triggerValue, onClick, ...props }, ref) => {
  const { value, onValueChange } = useContext(TabsContext)
  const isActive = value === triggerValue
  
  const handleClick = (e) => {
    onValueChange?.(triggerValue)
    onClick?.(e)
  }
  
  return (
    <button
      ref={ref}
      className={cn(
        "inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-white transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
        isActive 
          ? "bg-white text-slate-950 shadow-sm dark:bg-slate-950 dark:text-slate-50" 
          : "hover:bg-slate-200 dark:hover:bg-slate-700",
        className
      )}
      onClick={handleClick}
      data-state={isActive ? "active" : "inactive"}
      {...props}
    />
  )
})
TabsTrigger.displayName = "TabsTrigger"

const TabsContent = React.forwardRef(({ className, value: contentValue, ...props }, ref) => {
  const { value } = useContext(TabsContext)
  
  if (value !== contentValue) return null
  
  return (
    <div
      ref={ref}
      className={cn(
        "ring-offset-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2 dark:ring-offset-slate-950 dark:focus-visible:ring-slate-300",
        className
      )}
      {...props}
    />
  )
})
TabsContent.displayName = "TabsContent"

export { Tabs, TabsList, TabsTrigger, TabsContent }