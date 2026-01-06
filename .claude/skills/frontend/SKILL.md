# Frontend - Next.js/React/TypeScript Patterns

Next.js App Router with React, TypeScript, shadcn/ui, and NextAuth.js patterns.

---

## Tech Stack

| Library | Purpose |
|---------|---------|
| Next.js 16+ | React framework with App Router |
| React 19 | UI library |
| TypeScript 5 | Type safety |
| Tailwind CSS v4 | Utility-first styling |
| shadcn/ui | Component library |
| Zod | Schema validation |
| NextAuth.js | Authentication |
| Zustand | Client state management |
| React Query | Server state management |
| React Hook Form | Form handling |

---

## Project Structure

```
src/
├── app/                       # Next.js App Router
│   ├── (auth)/                # Auth route group (no layout)
│   │   ├── login/page.tsx
│   │   └── register/page.tsx
│   ├── (dashboard)/           # Dashboard route group
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── employees/page.tsx
│   ├── api/                   # API routes
│   │   └── auth/[...nextauth]/route.ts
│   ├── layout.tsx             # Root layout
│   ├── page.tsx               # Home page
│   └── globals.css
│
├── components/
│   ├── ui/                    # shadcn/ui components
│   │   ├── button.tsx
│   │   ├── input.tsx
│   │   ├── card.tsx
│   │   ├── dialog.tsx
│   │   ├── form.tsx
│   │   └── ...
│   ├── common/                # Custom shared components
│   │   └── DataTable.tsx
│   ├── layout/                # Layout components
│   │   ├── Header.tsx
│   │   ├── Sidebar.tsx
│   │   └── Footer.tsx
│   └── features/              # Feature-specific components
│       ├── employees/
│       └── departments/
│
├── hooks/                     # Custom React hooks
│   ├── useDebounce.ts
│   └── index.ts
│
├── services/                  # API service layer
│   ├── api.ts
│   └── index.ts
│
├── stores/                    # Zustand stores
│   ├── useAuthStore.ts
│   └── index.ts
│
├── types/                     # TypeScript types
│   └── index.ts
│
├── lib/                       # Utility libraries
│   ├── utils.ts               # cn() helper
│   ├── auth.ts                # NextAuth config
│   └── validations.ts         # Zod schemas
│
└── providers/                 # React providers
    ├── AuthProvider.tsx
    └── QueryProvider.tsx
```

---

## shadcn/ui Setup

> **Reference Repository**: https://github.com/vercel/registry-starter
>
> Follow the file structure and component patterns from this official Vercel registry starter.

### Configuration (components.json)

```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "src/app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "iconLibrary": "lucide"
}
```

### Installation

```bash
npx shadcn@latest init -y -d
```

### Adding Components

```bash
# Core UI components (install all at once)
npx shadcn@latest add button card input label badge dialog dropdown-menu table tabs avatar alert form select checkbox textarea separator skeleton sonner tooltip popover command -y

# Layout components
npx shadcn@latest add sidebar sheet scroll-area breadcrumb navigation-menu -y

# Form components
npx shadcn@latest add switch radio-group calendar accordion -y

# Additional components
npx shadcn@latest add drawer collapsible context-menu hover-card menubar resizable slider toggle toggle-group aspect-ratio input-otp alert-dialog progress pagination -y
```

### Available UI Components

| Component | Description |
|-----------|-------------|
| `accordion` | Collapsible content sections |
| `alert` | Callout for user attention |
| `alert-dialog` | Modal confirmation dialog |
| `avatar` | User profile image |
| `badge` | Status indicator |
| `breadcrumb` | Navigation path |
| `button` | Clickable actions |
| `calendar` | Date picker calendar |
| `card` | Content container |
| `checkbox` | Multiple selection |
| `collapsible` | Expandable content |
| `command` | Command palette |
| `context-menu` | Right-click menu |
| `dialog` | Modal overlay |
| `drawer` | Slide-out panel |
| `dropdown-menu` | Action menu |
| `form` | Form with validation |
| `hover-card` | Hover popup |
| `input` | Text input |
| `input-otp` | OTP code input |
| `label` | Form label |
| `menubar` | Desktop menu bar |
| `navigation-menu` | Site navigation |
| `pagination` | Page navigation |
| `popover` | Popup content |
| `progress` | Progress indicator |
| `radio-group` | Single selection |
| `resizable` | Resizable panels |
| `scroll-area` | Custom scrollbar |
| `select` | Dropdown select |
| `separator` | Visual divider |
| `sheet` | Side panel |
| `sidebar` | App sidebar |
| `skeleton` | Loading placeholder |
| `slider` | Range input |
| `sonner` | Toast notifications |
| `switch` | Toggle switch |
| `table` | Data table |
| `tabs` | Tabbed content |
| `textarea` | Multi-line input |
| `toggle` | Toggle button |
| `toggle-group` | Button group |
| `tooltip` | Hover hint |

### cn() Utility (lib/utils.ts)

```tsx
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

### Button Usage

```tsx
import { Button } from "@/components/ui/button";

// Variants
<Button variant="default">Default</Button>
<Button variant="destructive">Delete</Button>
<Button variant="outline">Outline</Button>
<Button variant="secondary">Secondary</Button>
<Button variant="ghost">Ghost</Button>
<Button variant="link">Link</Button>

// Sizes
<Button size="default">Default</Button>
<Button size="sm">Small</Button>
<Button size="lg">Large</Button>
<Button size="icon"><Icon /></Button>

// With loading state
<Button disabled={isLoading}>
  {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
  Submit
</Button>
```

### Card Component

```tsx
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

<Card>
  <CardHeader>
    <CardTitle>Employee Details</CardTitle>
    <CardDescription>View and edit employee information</CardDescription>
  </CardHeader>
  <CardContent>
    <p>Content here</p>
  </CardContent>
  <CardFooter>
    <Button>Save</Button>
  </CardFooter>
</Card>
```

### Dialog (Modal)

```tsx
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";

<Dialog>
  <DialogTrigger asChild>
    <Button>Open Dialog</Button>
  </DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Confirm Action</DialogTitle>
      <DialogDescription>
        Are you sure you want to proceed?
      </DialogDescription>
    </DialogHeader>
    <DialogFooter>
      <Button variant="outline">Cancel</Button>
      <Button>Confirm</Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

### Data Table

```tsx
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

<Table>
  <TableHeader>
    <TableRow>
      <TableHead>Name</TableHead>
      <TableHead>Email</TableHead>
      <TableHead>Status</TableHead>
      <TableHead className="text-right">Actions</TableHead>
    </TableRow>
  </TableHeader>
  <TableBody>
    {employees.map((employee) => (
      <TableRow key={employee.id}>
        <TableCell>{employee.name}</TableCell>
        <TableCell>{employee.email}</TableCell>
        <TableCell>
          <Badge variant={employee.status === "active" ? "default" : "secondary"}>
            {employee.status}
          </Badge>
        </TableCell>
        <TableCell className="text-right">
          <Button variant="ghost" size="sm">Edit</Button>
        </TableCell>
      </TableRow>
    ))}
  </TableBody>
</Table>
```

---

## Zod Validation Schemas

### Schema Definitions (lib/validations.ts)

```tsx
import { z } from "zod";

// Employee schema
export const employeeSchema = z.object({
  firstName: z
    .string()
    .min(1, "First name is required")
    .max(100, "First name is too long"),
  lastName: z
    .string()
    .min(1, "Last name is required")
    .max(100, "Last name is too long"),
  email: z
    .string()
    .min(1, "Email is required")
    .email("Invalid email address"),
  departmentId: z
    .string()
    .min(1, "Department is required"),
  position: z
    .string()
    .min(1, "Position is required"),
  status: z.enum(["active", "inactive", "on_leave"]),
});

export type EmployeeFormData = z.infer<typeof employeeSchema>;

// Login schema
export const loginSchema = z.object({
  email: z
    .string()
    .min(1, "Email is required")
    .email("Invalid email address"),
  password: z
    .string()
    .min(1, "Password is required")
    .min(8, "Password must be at least 8 characters"),
});

export type LoginFormData = z.infer<typeof loginSchema>;

// Register schema with password confirmation
export const registerSchema = z
  .object({
    name: z.string().min(1, "Name is required"),
    email: z.string().email("Invalid email address"),
    password: z.string().min(8, "Password must be at least 8 characters"),
    confirmPassword: z.string(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords don't match",
    path: ["confirmPassword"],
  });

export type RegisterFormData = z.infer<typeof registerSchema>;

// Leave request schema
export const leaveRequestSchema = z
  .object({
    type: z.enum(["annual", "sick", "personal", "unpaid"]),
    startDate: z.string().min(1, "Start date is required"),
    endDate: z.string().min(1, "End date is required"),
    reason: z.string().optional(),
  })
  .refine(
    (data) => new Date(data.endDate) >= new Date(data.startDate),
    {
      message: "End date must be after start date",
      path: ["endDate"],
    }
  );

export type LeaveRequestFormData = z.infer<typeof leaveRequestSchema>;
```

### Form with Zod + React Hook Form + shadcn/ui

```tsx
"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2 } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { employeeSchema, type EmployeeFormData } from "@/lib/validations";

interface EmployeeFormProps {
  onSubmit: (data: EmployeeFormData) => Promise<void>;
  defaultValues?: Partial<EmployeeFormData>;
  isLoading?: boolean;
}

export function EmployeeForm({
  onSubmit,
  defaultValues,
  isLoading = false,
}: EmployeeFormProps) {
  const form = useForm<EmployeeFormData>({
    resolver: zodResolver(employeeSchema),
    defaultValues: {
      firstName: "",
      lastName: "",
      email: "",
      departmentId: "",
      position: "",
      status: "active",
      ...defaultValues,
    },
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
        <div className="grid grid-cols-2 gap-4">
          <FormField
            control={form.control}
            name="firstName"
            render={({ field }) => (
              <FormItem>
                <FormLabel>First Name</FormLabel>
                <FormControl>
                  <Input placeholder="John" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="lastName"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Last Name</FormLabel>
                <FormControl>
                  <Input placeholder="Doe" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
        </div>

        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input type="email" placeholder="john@example.com" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="status"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Status</FormLabel>
              <Select onValueChange={field.onChange} defaultValue={field.value}>
                <FormControl>
                  <SelectTrigger>
                    <SelectValue placeholder="Select status" />
                  </SelectTrigger>
                </FormControl>
                <SelectContent>
                  <SelectItem value="active">Active</SelectItem>
                  <SelectItem value="inactive">Inactive</SelectItem>
                  <SelectItem value="on_leave">On Leave</SelectItem>
                </SelectContent>
              </Select>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button type="submit" disabled={isLoading}>
          {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          {isLoading ? "Saving..." : "Save Employee"}
        </Button>
      </form>
    </Form>
  );
}
```

---

## NextAuth.js Setup

### Installation

```bash
npm install next-auth
```

### Auth Configuration (lib/auth.ts)

```tsx
import { type NextAuthOptions } from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";
import GoogleProvider from "next-auth/providers/google";

export const authOptions: NextAuthOptions = {
  providers: [
    // Credentials provider (email/password)
    CredentialsProvider({
      name: "credentials",
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          throw new Error("Invalid credentials");
        }

        // Call your backend API to verify credentials
        const response = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL}/auth/login`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              email: credentials.email,
              password: credentials.password,
            }),
          }
        );

        if (!response.ok) {
          throw new Error("Invalid credentials");
        }

        const user = await response.json();
        return user;
      },
    }),

    // Google OAuth (optional)
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
  ],

  session: {
    strategy: "jwt",
    maxAge: 30 * 24 * 60 * 60, // 30 days
  },

  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id;
        token.role = user.role;
      }
      return token;
    },
    async session({ session, token }) {
      if (session.user) {
        session.user.id = token.id as string;
        session.user.role = token.role as string;
      }
      return session;
    },
  },

  pages: {
    signIn: "/login",
    error: "/login",
  },
};
```

### API Route (app/api/auth/[...nextauth]/route.ts)

```tsx
import NextAuth from "next-auth";
import { authOptions } from "@/lib/auth";

const handler = NextAuth(authOptions);

export { handler as GET, handler as POST };
```

### Auth Types (types/next-auth.d.ts)

```tsx
import { DefaultSession, DefaultUser } from "next-auth";

declare module "next-auth" {
  interface Session {
    user: {
      id: string;
      role: "admin" | "manager" | "employee";
    } & DefaultSession["user"];
  }

  interface User extends DefaultUser {
    id: string;
    role: "admin" | "manager" | "employee";
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    id: string;
    role: "admin" | "manager" | "employee";
  }
}
```

### Session Provider (providers/AuthProvider.tsx)

```tsx
"use client";

import { SessionProvider } from "next-auth/react";
import type { ReactNode } from "react";

interface AuthProviderProps {
  children: ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps) {
  return <SessionProvider>{children}</SessionProvider>;
}
```

### Root Layout with Provider

```tsx
// app/layout.tsx
import { AuthProvider } from "@/providers/AuthProvider";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
```

### Login Page

```tsx
"use client";

import { useState } from "react";
import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2 } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { loginSchema, type LoginFormData } from "@/lib/validations";

export default function LoginPage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const form = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: "",
      password: "",
    },
  });

  const onSubmit = async (data: LoginFormData) => {
    setIsLoading(true);
    setError(null);

    try {
      const result = await signIn("credentials", {
        email: data.email,
        password: data.password,
        redirect: false,
      });

      if (result?.error) {
        setError("Invalid email or password");
        return;
      }

      router.push("/dashboard");
      router.refresh();
    } catch {
      setError("Something went wrong");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>Login</CardTitle>
          <CardDescription>
            Enter your credentials to access the HR Portal
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
              {error && (
                <div className="rounded-md bg-destructive/15 p-3 text-sm text-destructive">
                  {error}
                </div>
              )}

              <FormField
                control={form.control}
                name="email"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Email</FormLabel>
                    <FormControl>
                      <Input type="email" placeholder="you@example.com" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="password"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Password</FormLabel>
                    <FormControl>
                      <Input type="password" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <Button type="submit" className="w-full" disabled={isLoading}>
                {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                Sign In
              </Button>
            </form>
          </Form>
        </CardContent>
      </Card>
    </div>
  );
}
```

### Protected Route Middleware (middleware.ts)

```tsx
import { withAuth } from "next-auth/middleware";
import { NextResponse } from "next/server";

export default withAuth(
  function middleware(req) {
    const token = req.nextauth.token;
    const isAdminRoute = req.nextUrl.pathname.startsWith("/admin");

    // Check role for admin routes
    if (isAdminRoute && token?.role !== "admin") {
      return NextResponse.redirect(new URL("/unauthorized", req.url));
    }

    return NextResponse.next();
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
);

export const config = {
  matcher: ["/dashboard/:path*", "/employees/:path*", "/admin/:path*"],
};
```

### useSession Hook Usage

```tsx
"use client";

import { useSession, signOut } from "next-auth/react";

export function UserNav() {
  const { data: session, status } = useSession();

  if (status === "loading") {
    return <div>Loading...</div>;
  }

  if (!session) {
    return null;
  }

  return (
    <div className="flex items-center gap-4">
      <span>{session.user.name}</span>
      <span className="text-muted-foreground">{session.user.role}</span>
      <Button variant="outline" onClick={() => signOut()}>
        Sign Out
      </Button>
    </div>
  );
}
```

### Server Component Auth Check

```tsx
// app/dashboard/page.tsx
import { getServerSession } from "next-auth";
import { redirect } from "next/navigation";
import { authOptions } from "@/lib/auth";

export default async function DashboardPage() {
  const session = await getServerSession(authOptions);

  if (!session) {
    redirect("/login");
  }

  return (
    <div>
      <h1>Welcome, {session.user.name}</h1>
      <p>Role: {session.user.role}</p>
    </div>
  );
}
```

---

## Environment Variables

```env
# NextAuth.js
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key-here

# API
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1

# OAuth (optional)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

---

## Import Order

```tsx
// 1. React/Next.js imports
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";

// 2. Third-party libraries
import { useSession } from "next-auth/react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Loader2, Plus, Edit, Trash } from "lucide-react";

// 3. shadcn/ui components
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

// 4. Custom components
import { DataTable } from "@/components/common/DataTable";
import { EmployeeForm } from "@/components/features/employees/EmployeeForm";

// 5. Hooks, services, stores
import { useDebounce } from "@/hooks";
import { employeeService } from "@/services";
import { useEmployeeStore } from "@/stores";

// 6. Types and utilities
import type { Employee } from "@/types";
import { cn } from "@/lib/utils";
import { employeeSchema } from "@/lib/validations";
```

---

## DO NOT

- Use `any` type - use `unknown` or proper types
- Skip Zod validation on forms
- Store sensitive data in client state
- Use inline styles - use Tailwind classes
- Skip loading/error states
- Hardcode API URLs - use environment variables
- Skip TypeScript strict mode
- Mix server and client components incorrectly
- Leave `console.log` in production
- Skip accessibility (aria-*, roles)
