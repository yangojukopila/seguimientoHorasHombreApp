// ============================================
// Core TypeScript Models
// ============================================

export interface Employee {
    id: string;
    cedula: string;
    full_name: string;
    position: string;
    status: 'active' | 'inactive';
    created_at: string;
    updated_at: string;
}

export interface Project {
    id: string;
    code: string;
    name: string;
    client: string;
    status: 'active' | 'closed';
    created_at: string;
    updated_at: string;
}

export interface Island {
    id: string;
    name: string;
    token: string;
    status: 'active' | 'inactive';
    created_at: string;
    last_activity: string | null;
}

export interface HoursBreakdown {
    ordinaria_diurna: number;
    ordinaria_nocturna: number;
    extra_diurna: number;
    extra_nocturna: number;
    dominical_festiva_diurna: number;
    dominical_festiva_nocturna: number;
}

export interface TimeRecord {
    id: string;
    employee_id: string;
    project_id: string;
    island_id: string;
    check_in: string;
    check_out: string | null;
    hours_breakdown: HoursBreakdown;
    created_at: string;
    updated_at: string;
    // Joined data
    employee?: Employee;
    project?: Project;
    island?: Island;
}

export interface Holiday {
    id: string;
    date: string;
    name: string;
    year: number;
    created_at: string;
}

export interface CheckInRequest {
    cedula: string;
    project_id: string;
    island_token: string;
}

export interface CheckOutRequest {
    cedula: string;
    island_token: string;
}

export interface ReportFilters {
    start_date?: string;
    end_date?: string;
    employee_id?: string;
    project_id?: string;
    hour_type?: keyof HoursBreakdown;
}

export interface DashboardStats {
    active_employees: number;
    active_projects: number;
    today_checkins: number;
    week_hours: HoursBreakdown;
}
